/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0, or
 * GNU General Public License version 2, or
 * GNU Lesser General Public License version 2.1.
 */
package org.truffleruby.core;

import java.lang.ref.ReferenceQueue;
import java.lang.ref.WeakReference;
import java.util.ArrayList;

import org.truffleruby.RubyContext;
import org.truffleruby.core.queue.UnsizedQueue;

import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.api.object.DynamicObject;

/**
 * Class to provide GC marking and other facilities to keep objects alive for native extensions.
 *
 * Native extensions expect objects on the stack to be kept alive even when they have been stored in
 * native structures on the stack (e.g. pg keeps the VALUE of a ruby array in a structure on the
 * stack, and places other objects in that array to keep them alive). They also expect structs in
 * objects with custom mark functions to keep marked objects alive.
 *
 * Since we are not running on a VM that allows us to add custom mark functions to our garbage
 * collector we keep objects alive in 2 ways. Any object converted to a native handle can be kept
 * alive by executing a {@link MarkingServiceNodes.KeepAliveNode}. This will add the object to two
 * lists, a list of all objects converted to native during this call to a C extension function which
 * will be popped when the we return to Ruby code, and a fixed sized list of objects converted to
 * native handles. When the latter of these two lists is full all mark functions will be run the
 * next time an object is added.
 *
 * Marker references only keep a week reference to their owning object to ensure they don't
 * themselves stop the object from being garbage collected.
 *
 */
public class MarkingService extends ReferenceProcessingService<MarkingService.MarkerReference> {

    public static interface MarkerAction {
        public abstract void mark(DynamicObject owner);
    }

    public static class MarkerReference extends WeakReference<DynamicObject> implements ReferenceProcessingService.ProcessingReference<MarkerReference> {

        private final MarkerAction action;
        private final MarkingService service;
        private MarkerReference next = null;
        private MarkerReference prev = null;

        private MarkerReference(DynamicObject object, ReferenceQueue<? super Object> queue, MarkerAction action, MarkingService service) {
            super(object, queue);
            this.action = action;
            this.service = service;
        }

        public MarkerReference getPrevious() {
            return prev;
        }

        public void setPrevious(MarkerReference previous) {
            prev = previous;
        }

        public MarkerReference getNext() {
            return next;
        }

        public void setNext(MarkerReference next) {
            this.next = next;
        }

        public ReferenceProcessingService<MarkerReference> service() {
            return service;
        }
    }

    public static class MarkRunnerReference extends WeakReference<Object> implements ReferenceProcessingService.ProcessingReference<MarkRunnerReference> {

        private final MarkRunnerService service;
        private MarkRunnerReference next = null;
        private MarkRunnerReference prev = null;

        public MarkRunnerReference(Object object, ReferenceQueue<? super Object> queue, MarkRunnerService service) {
            super(object, queue);
            this.service = service;
        }

        public MarkRunnerReference getPrevious() {
            return prev;
        }

        public void setPrevious(MarkRunnerReference previous) {
            prev = previous;
        }

        public MarkRunnerReference getNext() {
            return next;
        }

        public void setNext(MarkRunnerReference next) {
            this.next = next;
        }

        public ReferenceProcessingService<MarkRunnerReference> service() {
            return service;
        }
    }

    /**
     * This service handles actually running the mark functions when this is needed. It's done this
     * way so that mark functions and finalizers are run on the same thread, and so that we can
     * avoid the use of any additional locks in this process (as these may cause deadlocks).
     *
     */
    public static class MarkRunnerService extends ReferenceProcessingService<MarkingService.MarkRunnerReference> {

        private final MarkingService markingService;

        public MarkRunnerService(RubyContext context, ReferenceProcessor referenceProcessor, MarkingService markingService) {
            super(context, referenceProcessor);
            this.markingService = markingService;
        }

        @Override
        protected void processReference(ProcessingReference<?> reference) {
            ArrayList<Object[]> keptObjectLists = new ArrayList<>();
            Object[] list;
            while (true) {
                list = (Object[]) markingService.keptObjectQueue.poll();
                if (list == null) {
                    break;
                } else {
                    keptObjectLists.add(list);
                }
            }
            if (!keptObjectLists.isEmpty()) {
                runAllMarkers();
            }
            super.processReference(reference);
            keptObjectLists.clear();
        }

        @TruffleBoundary
        public void runAllMarkers() {
            MarkerReference currentMarker = markingService.getFirst();
            MarkerReference nextMarker;
            while (currentMarker != null) {
                nextMarker = currentMarker.getNext();
                markingService.runMarker(currentMarker);
                if (nextMarker == currentMarker) {
                    throw new Error("The MarkerReference linked list structure has become broken.");
                }
                currentMarker = nextMarker;
            }
        }
    }

    private final int cacheSize;

    private final ThreadLocal<MarkerThreadLocalData> threadLocalData;

    private final MarkRunnerService runnerService;

    private final UnsizedQueue keptObjectQueue = new UnsizedQueue();

    public static class MarkerThreadLocalData {
        private final MarkerKeptObjects keptObjects;
        private final MarkerStack preservationStack;

        public MarkerThreadLocalData(MarkingService service) {
            this.preservationStack = new MarkerStack();
            this.keptObjects = new MarkerKeptObjects(service);
        }

        public MarkerKeptObjects getKeptObjects() {
            return keptObjects;
        }

        public MarkerStack getPreservationStack() {
            return preservationStack;
        }
    }

    public static class MarkerKeptObjects {
        private final MarkingService service;
        protected Object[] objects;
        protected int counter;

        protected MarkerKeptObjects(MarkingService service) {
            objects = new Object[service.cacheSize];
            counter = 0;
            this.service = service;
        }

        public void keepObject(Object object) {
            /*
             * It is important to get the ordering of events correct to avoid references being
             * garbage collected too soon. If we are attempting to add a handle to a native
             * structure then that consists of two events. First we create the handle, and then the
             * handle is stored in the struct. If we run mark functions immediate after adding the
             * handle to the list of kept objects then the mark function will be run before that
             * handle is stored in the structure, and since it will be removed from the list of kept
             * objects it could be collected before the mark functions are run again.
             *
             * Instead we check for the kept list being full before adding an object to it, as those
             * handles are already stored in structs by this point.
             */
            if (isFull()) {
                queueAndReset();
            }
            objects[counter++] = object;
        }

        private void queueAndReset() {
            service.queueForMarking(objects);
            objects = new Object[service.cacheSize];
            counter = 0;
        }

        private boolean isFull() {
            return counter == service.cacheSize;
        }

        public void keepObjects(MarkerKeptObjects otherObjects) {
            if (isFull()) {
                queueAndReset();
            }
            if (otherObjects.isFull()) {
                service.queueForMarking(otherObjects.objects);
                return;
            } else if (otherObjects.counter == 0) {
                return;
            } else if (otherObjects.counter + counter <= service.cacheSize) {
                System.arraycopy(otherObjects.objects, 0, objects, counter, otherObjects.counter);
                counter += otherObjects.counter;
                return;
            } else {
                int overflowLength = counter + otherObjects.counter - service.cacheSize;
                int initialLength = otherObjects.counter - overflowLength;
                System.arraycopy(otherObjects.objects, 0, objects, counter, initialLength);
                counter = service.cacheSize;
                queueAndReset();
                System.arraycopy(otherObjects.objects, initialLength, objects, 0, overflowLength);
                counter = overflowLength;
                return;
            }
        }

    }

    protected static class MarkerStackEntry {
        protected final MarkerStackEntry previous;
        protected final ArrayList<Object> entries = new ArrayList<>();

        protected MarkerStackEntry(MarkerStackEntry previous) {
            this.previous = previous;
        }
    }

    public static class MarkerStack {
        protected MarkerStackEntry current = new MarkerStackEntry(null);

        public ArrayList<Object> get() {
            return current.entries;
        }

        public void pop() {
            current = current.previous;
        }

        public void push() {
            current = new MarkerStackEntry(current);
        }
    }

    @TruffleBoundary
    public MarkerThreadLocalData getThreadLocalData() {
        return threadLocalData.get();
    }

    public MarkingService(RubyContext context, ReferenceProcessor referenceProcessor) {
        super(context, referenceProcessor);
        cacheSize = context.getOptions().CEXTS_MARKING_CACHE;
        threadLocalData = ThreadLocal.withInitial(this::makeThreadLocalData);
        runnerService = new MarkRunnerService(context, referenceProcessor, this);
    }

    @TruffleBoundary
    public MarkerThreadLocalData makeThreadLocalData() {
        MarkerThreadLocalData data = new MarkerThreadLocalData(this);
        MarkerKeptObjects keptObjects = data.getKeptObjects();
        context.getFinalizationService().addFinalizer(data, null, MarkingService.class, () -> getThreadLocalData().keptObjects.keepObjects(keptObjects), null);
        return data;
    }

    @TruffleBoundary
    public void queueForMarking(Object[] objects) {
        keptObjectQueue.add(objects);
        runnerService.add(new MarkRunnerReference(new Object(), referenceProcessor.processingQueue, runnerService));
    }

    public void addMarker(DynamicObject object, MarkerAction action) {
        add(new MarkerReference(object, referenceProcessor.processingQueue, action, this));
    }

    private void runMarker(MarkerReference markerReference) {
        runCatchingErrors(this::runMarkerInternal, markerReference);
    }

    private void runMarkerInternal(MarkerReference markerReference) {
        if (!context.isFinalizing()) {
            DynamicObject owner = markerReference.get();
            if (owner != null) {
                final MarkerAction action = markerReference.action;
                action.mark(owner);
            }
        }
    }
}
