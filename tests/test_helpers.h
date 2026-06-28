#ifndef GRIDVAL_TEST_HELPERS_H
#define GRIDVAL_TEST_HELPERS_H

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline void assert_int_equal(int actual, int expected, const char *message) {
  if (actual != expected) {
    fprintf(stderr, "FAIL %s: expected %d, got %d.\n", message, expected, actual);
    exit(1);
  }
}

static inline void assert_size_equal(size_t actual, size_t expected, const char *message) {
  if (actual != expected) {
    fprintf(stderr, "FAIL %s: expected %zu, got %zu.\n", message, expected, actual);
    exit(1);
  }
}

static inline void assert_double_equal(double actual, 
  double expected, 
  double tolerance, 
  const char *message
  )
  {
    if (fabs(actual - expected) > tolerance) {
      fprintf(stderr, "FAIL %s: expected %.6f, got %.6f.\n", message, expected, actual);
      exit(1);
    }
  }

  static inline void assert_string_contains(const char *haystack, 
    const char *needle, 
    const char *message
  )
  {
    if (strstr(haystack, needle) == NULL) {
      fprintf(stderr, "FAIL %s: expected to find %s.\n", message, needle);
      exit(1);
    }
  }

#endif
