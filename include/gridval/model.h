#ifndef GRIDVAL_MODEL_H
#define GRIDVAL_MODEL_H

#include <stddef.h>

#define GRIDVAL_ID_SIZE 64
#define GRIDVAL_SCENARIO_NAME_SIZE 128

typedef struct
{
  char id[GRIDVAL_ID_SIZE];
  double voltage_pu;
} Bus;

typedef struct 
{
  char id[GRIDVAL_ID_SIZE];
  double loading_percent;
} Line;

typedef struct
{
  char id[GRIDVAL_ID_SIZE];
  double loading_percent;
} Transformer;

typedef struct
{
  Bus *items;
  size_t count;
  size_t capacity;
} BusArray;

typedef struct
{
  Line *items;
  size_t count;
  size_t capacity;
} LineArray;

typedef struct
{
  Transformer *items;
  size_t count;
  size_t capacity;
} TransformerArray;

typedef struct
{
  char name[GRIDVAL_SCENARIO_NAME_SIZE];
  BusArray buses;
  LineArray lines;
  TransformerArray transformers;
} Scenario;

int bus_array_init(BusArray *array);
int bus_array_append(BusArray *array, Bus value);
void bus_array_free(BusArray *array);

int line_array_init(LineArray *array);
int line_array_append(LineArray *array, Line value);
void line_array_free(LineArray *array);

int transformer_array_init(TransformerArray *array);
int transformer_array_append(TransformerArray *array, Transformer value);
void transformer_array_free(TransformerArray *array);

int scenario_init(Scenario *scenario);
void scenario_free(Scenario *scenario);

#endif
