# Copyright (c) 2017, 2019 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 2.0, or
# GNU General Public License version 2, or
# GNU Lesser General Public License version 2.1.

require 'objspace'

require_relative '../../ruby/spec_helper'

describe "ObjectSpace.define_finalizer" do

  # These specs require that the GC runs a full stop-the-world collection that
  # will push references on Runtime#gc(). All GCs on HotSpot and the SVM do
  # this, apart from the Epsilon collector on HotSpot. The remaining issue is
  # that the references are popped asynchronously at the JVM level, and then
  # from there popped again asynchronously in TruffleRuby, so we do still need
  # to wait with a timeout in order to assert that it has been done.
  # Truffle::Debug.drain_finalization_queue, which drains the queue in
  # TruffleRuby in the foreground, does seem to help increase test throughput.

  it "will call the finalizer" do
    channel = Truffle::Channel.new
    finalizer = proc {
      channel.send :finalized
    }
    Object.new.tap do |object|
      ObjectSpace.define_finalizer object, finalizer
      ObjectSpace.reachable_objects_from(object).should include(finalizer)
    end
    GC.start
    Truffle::Debug.drain_finalization_queue   # Not needed for correctness
    channel.receive_timeout(3).should == :finalized
  end

end
