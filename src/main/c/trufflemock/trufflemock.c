/*
 * Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0
 * GNU General Public License version 2
 * GNU Lesser General Public License version 2.1
 *
 */

// This file is automatically generated by ruby tool/generate-trufflemock.rb

#include <stdio.h>
#include <truffle.h>

void rb_tr_mock() {
  fprintf(stderr, "Warning: Mock method called in trufflemock\n");
  abort();
}

void *truffle_import(const char *name) {
  rb_tr_mock();
  return 0;
}

void *truffle_import_cached(const char *name) {
  rb_tr_mock();
  return 0;
}

void *truffle_address_to_function(void *address) {
  rb_tr_mock();
  return 0;
}

void *truffle_get_arg(int i) {
  rb_tr_mock();
  return 0;
}

bool truffle_is_executable(const void *object) {
  rb_tr_mock();
  return false;
}

bool truffle_is_null(const void *object) {
  rb_tr_mock();
  return false;
}

bool truffle_has_size(const void *object) {
  rb_tr_mock();
  return false;
}

bool truffle_is_boxed(const void *object) {
  rb_tr_mock();
  return false;
}

bool truffle_is_truffle_object(const void *object) {
  rb_tr_mock();
  return false;
}

void *truffle_execute(void *object, ...) {
  rb_tr_mock();
  return 0;
}

int truffle_execute_i(void *object, ...) {
  rb_tr_mock();
  return 0;
}

long truffle_execute_l(void *object, ...) {
  rb_tr_mock();
  return 0;
}

char truffle_execute_c(void *object, ...) {
  rb_tr_mock();
  return '0';
}

float truffle_execute_f(void *object, ...) {
  rb_tr_mock();
  return 0.0;
}

double truffle_execute_d(void *object, ...) {
  rb_tr_mock();
  return 0.0;
}

bool truffle_execute_b(void *object, ...) {
  rb_tr_mock();
  return false;
}

void *truffle_invoke(void *object, const char *name, ...) {
  rb_tr_mock();
  return 0;
}

int truffle_invoke_i(void *object, const char *name, ...) {
  rb_tr_mock();
  return 0;
}

long truffle_invoke_l(void *object, const char *name, ...) {
  rb_tr_mock();
  return 0;
}

char truffle_invoke_c(void *object, const char *name, ...) {
  rb_tr_mock();
  return '0';
}

float truffle_invoke_f(void *object, const char *name, ...) {
  rb_tr_mock();
  return 0.0;
}

double truffle_invoke_d(void *object, const char *name, ...) {
  rb_tr_mock();
  return 0.0;
}

bool truffle_invoke_b(void *object, const char *name, ...) {
  rb_tr_mock();
  return false;
}

int truffle_get_size(void *object) {
  rb_tr_mock();
  return 0;
}

int truffle_unbox_i(void *object) {
  rb_tr_mock();
  return 0;
}

long truffle_unbox_l(void *object) {
  rb_tr_mock();
  return 0;
}

char truffle_unbox_c(void *object) {
  rb_tr_mock();
  return '0';
}

float truffle_unbox_f(void *object) {
  rb_tr_mock();
  return 0.0;
}

double truffle_unbox_d(void *object) {
  rb_tr_mock();
  return 0.0;
}

bool truffle_unbox_b(void *object) {
  rb_tr_mock();
  return false;
}

void *truffle_read(void *object, const char *name) {
  rb_tr_mock();
  return 0;
}

int truffle_read_i(void *object, const char *name) {
  rb_tr_mock();
  return 0;
}

long truffle_read_l(void *object, const char *name) {
  rb_tr_mock();
  return 0;
}

char truffle_read_c(void *object, const char *name) {
  rb_tr_mock();
  return '0';
}

float truffle_read_f(void *object, const char *name) {
  rb_tr_mock();
  return 0.0;
}

double truffle_read_d(void *object, const char *name) {
  rb_tr_mock();
  return 0.0;
}

bool truffle_read_b(void *object, const char *name) {
  rb_tr_mock();
  return false;
}

void *truffle_read_idx(void *object, int idx) {
  rb_tr_mock();
  return 0;
}

int truffle_read_idx_i(void *object, int idx) {
  rb_tr_mock();
  return 0;
}

long truffle_read_idx_l(void *object, int idx) {
  rb_tr_mock();
  return 0;
}

char truffle_read_idx_c(void *object, int idx) {
  rb_tr_mock();
  return '0';
}

float truffle_read_idx_f(void *object, int idx) {
  rb_tr_mock();
  return 0.0;
}

double truffle_read_idx_d(void *object, int idx) {
  rb_tr_mock();
  return 0.0;
}

bool truffle_read_idx_b(void *object, int idx) {
  rb_tr_mock();
  return false;
}

void truffle_write(void *object, const char *name, void *value) {
  rb_tr_mock();
}

void truffle_write_i(void *object, const char *name, int value) {
  rb_tr_mock();
}

void truffle_write_l(void *object, const char *name, long value) {
  rb_tr_mock();
}

void truffle_write_c(void *object, const char *name, char value) {
  rb_tr_mock();
}

void truffle_write_f(void *object, const char *name, float value) {
  rb_tr_mock();
}

void truffle_write_d(void *object, const char *name, double value) {
  rb_tr_mock();
}

void truffle_write_b(void *object, const char *name, bool value) {
  rb_tr_mock();
}

void truffle_write_idx(void *object, int idx, void *value) {
  rb_tr_mock();
}

void truffle_write_idx_i(void *object, int idx, int value) {
  rb_tr_mock();
}

void truffle_write_idx_l(void *object, int idx, long value) {
  rb_tr_mock();
}

void truffle_write_idx_c(void *object, int idx, char value) {
  rb_tr_mock();
}

void truffle_write_idx_f(void *object, int idx, float value) {
  rb_tr_mock();
}

void truffle_write_idx_d(void *object, int idx, double value) {
  rb_tr_mock();
}

void truffle_write_idx_b(void *object, int idx, bool value) {
  rb_tr_mock();
}

void *truffle_read_string(const char *string) {
  rb_tr_mock();
  return 0;
}

void *truffle_read_n_string(const char *string, int n) {
  rb_tr_mock();
  return 0;
}

void *truffle_read_bytes(const char *bytes) {
  rb_tr_mock();
  return 0;
}

void *truffle_read_n_bytes(const char *bytes, int n) {
  rb_tr_mock();
  return 0;
}

void *truffle_managed_malloc(long size) {
  rb_tr_mock();
  return 0;
}

void *truffle_managed_memcpy(void *destination, const void *source, size_t count) {
  rb_tr_mock();
  return 0;
}

void *truffle_handle_for_managed(void *managedObject) {
  rb_tr_mock();
  return 0;
}

void *truffle_release_handle(void *nativeHandle) {
  rb_tr_mock();
  return 0;
}

void *truffle_managed_from_handle(void *nativeHandle) {
  rb_tr_mock();
  return 0;
}

void *truffle_sulong_function_to_native_pointer(void *sulongFunctionPointer, const void *signature) {
  rb_tr_mock();
  return 0;
}

void truffle_load_library(const char *string) {
  rb_tr_mock();
}

