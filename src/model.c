#include "gridval/model.h"

#include <stdlib.h>
#include <string.h>

#define INITIAL_CAPACITY 4

static int grow_bus_array(BusArray *array)
{
  size_t new_capacity = array->capacity == 0 ? INITIAL_CAPACITY : array->capacity * 2;
  Bus *new_items = realloc(array->items, new_capacity * sizeof(array->items[0]));
  if (new_items == NULL) {
    return 1;
  }
  array->items    = new_items;
  array->capacity = new_capacity;
  return 0;
}

int bus_array_init(BusArray *array)
{
  if (array == NULL){
    return 1;
  }
  // `->` is a shorthand for `(*array).count`
  // the parenthesis matter because `.` has high precedence than `*`
  array->items    = NULL;  // it means "follow the pointer and access the `count` field."
  array->count    = 0;
  array->capacity = 0;
  return 0;
}

int bus_array_append(BusArray *array, Bus value)
{
  if (array == NULL) {
    return 1;
  }
  if (array->capacity == array->count && grow_bus_array(array) != 0) {
    return 1;
  }
  array->items[array->count] = value;
  array->count += 1;
  return 0;
}