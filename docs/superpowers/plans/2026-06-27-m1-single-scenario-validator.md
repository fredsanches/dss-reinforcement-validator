# M1 Single-Scenario Validator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first `gridval validate` CLI that reads one CSV scenario, validates voltage/loading constraints, and writes a Markdown report.

**Architecture:** Use small C17 modules with headers in `include/gridval/` and implementations in `src/`. Store buses, lines, transformers, and violations in dynamic arrays backed by heap memory so the tool can read scenarios of unknown size.

**Tech Stack:** C17, Apple clang, Makefile, standard C library only, small C executable tests.

---

## File Structure

- Create: `Makefile`  
  Builds the CLI and test binaries with strict warnings.
- Create: `include/gridval/model.h` and `src/model.c`  
  Defines domain structs, dynamic arrays, `malloc/realloc/free` ownership helpers.
- Create: `include/gridval/config.h` and `src/config.c`  
  Defines validation limits and parses `key=value` config files.
- Create: `include/gridval/validation.h` and `src/validation.c`  
  Validates loaded scenarios and appends violations.
- Create: `include/gridval/csv.h` and `src/csv.c`  
  Loads scenario CSV files.
- Create: `include/gridval/report.h` and `src/report.c`  
  Writes Markdown reports.
- Create: `src/main.c`  
  Parses `gridval validate --scenario ... --config ... --out ...`.
- Create: `tests/test_model.c`, `tests/test_validation.c`, `tests/test_config.c`, `tests/test_csv.c`, `tests/test_report.c`  
  C executable tests.
- Create: `tests/test_helpers.h`  
  Tiny assertion helpers.
- Create: `tests/fixtures/simple_valid/` and `tests/fixtures/malformed/`  
  Deterministic parser fixtures.
- Create/modify: `examples/config.ini`, `examples/scenario_with_pv/*.csv`  
  Sample scenario with known violations.
- Create/modify: `docs/scenario-format.md`, `docs/validation-rules.md`, `README.md`  
  User-facing milestone documentation.

---

### Task 1: Build System and Test Harness

**Files:**
- Create: `Makefile`
- Create: `tests/test_helpers.h`
- Create: `tests/test_smoke.c`

- [ x ] **Step 1: Create a failing smoke test**

Create `tests/test_smoke.c`:

```c
#include "test_helpers.h"

int main(void)
{
    assert_int_equal(1, 1, "basic integer assertion works");
    return 0;
}
```

Create `tests/test_helpers.h`:

```c
#ifndef GRIDVAL_TEST_HELPERS_H
#define GRIDVAL_TEST_HELPERS_H

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void assert_int_equal(int actual, int expected, const char *message)
{
    if (actual != expected) {
        fprintf(stderr, "FAIL: %s: expected %d, got %d\n", message, expected, actual);
        exit(1);
    }
}

static void assert_size_equal(size_t actual, size_t expected, const char *message)
{
    if (actual != expected) {
        fprintf(stderr, "FAIL: %s: expected %zu, got %zu\n", message, expected, actual);
        exit(1);
    }
}

static void assert_double_equal(double actual, double expected, double tolerance, const char *message)
{
    if (fabs(actual - expected) > tolerance) {
        fprintf(stderr, "FAIL: %s: expected %.6f, got %.6f\n", message, expected, actual);
        exit(1);
    }
}

static void assert_string_contains(const char *haystack, const char *needle, const char *message)
{
    if (strstr(haystack, needle) == NULL) {
        fprintf(stderr, "FAIL: %s: expected to find '%s'\n", message, needle);
        exit(1);
    }
}

#endif
```

- [ x ] **Step 2: Run test before Makefile exists**

Run: `make test`

Expected: FAIL because there is no `Makefile`.

- [ x ] **Step 3: Add the minimal Makefile**

Create `Makefile`:

```make
CC := /usr/bin/clang
CFLAGS := -std=c17 -Wall -Wextra -Wpedantic -Wconversion -Wshadow -g -O0
CPPFLAGS := -Iinclude -Itests

BUILD_DIR := build
SRC := src/model.c src/config.c src/validation.c src/csv.c src/report.c
APP_SRC := src/main.c
TEST_BINS := \
	$(BUILD_DIR)/test_smoke \
	$(BUILD_DIR)/test_model \
	$(BUILD_DIR)/test_validation \
	$(BUILD_DIR)/test_config \
	$(BUILD_DIR)/test_csv \
	$(BUILD_DIR)/test_report

.PHONY: all test clean

all: $(BUILD_DIR)/gridval

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/gridval: $(SRC) $(APP_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(SRC) $(APP_SRC) -o $@

$(BUILD_DIR)/test_smoke: tests/test_smoke.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_smoke.c -o $@

$(BUILD_DIR)/test_model: tests/test_model.c src/model.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_model.c src/model.c -o $@

$(BUILD_DIR)/test_validation: tests/test_validation.c src/model.c src/validation.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_validation.c src/model.c src/validation.c -o $@

$(BUILD_DIR)/test_config: tests/test_config.c src/config.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_config.c src/config.c -o $@

$(BUILD_DIR)/test_csv: tests/test_csv.c src/model.c src/csv.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_csv.c src/model.c src/csv.c -o $@

$(BUILD_DIR)/test_report: tests/test_report.c src/model.c src/report.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_report.c src/model.c src/report.c -o $@

test: $(TEST_BINS)
	$(BUILD_DIR)/test_smoke
	$(BUILD_DIR)/test_model
	$(BUILD_DIR)/test_validation
	$(BUILD_DIR)/test_config
	$(BUILD_DIR)/test_csv
	$(BUILD_DIR)/test_report

clean:
	rm -rf $(BUILD_DIR)
```

- [ x ] **Step 4: Run the smoke test**

Run: `make build/test_smoke && build/test_smoke`

Expected: PASS with no output.

- [ x   ] **Step 5: Commit**

Run:

```bash
git add Makefile tests/test_helpers.h tests/test_smoke.c .gitignore
git commit -m "chore: add build and test harness"
```

---

### Task 2: Domain Model and Dynamic Arrays

**Files:**
- Create: `include/gridval/model.h`
- Create: `src/model.c`
- Create: `tests/test_model.c`

- [ x ] **Step 1: Write failing dynamic array tests**

Create `tests/test_model.c`:

```c
#include "gridval/model.h"
#include "test_helpers.h"

static void test_bus_array_grows(void)
{
    BusArray buses;
    assert_int_equal(bus_array_init(&buses), 0, "bus array init succeeds");

    Bus first = { "MT_001", 1.000 };
    Bus second = { "MT_002", 1.064 };

    assert_int_equal(bus_array_append(&buses, first), 0, "append first bus");
    assert_int_equal(bus_array_append(&buses, second), 0, "append second bus");

    assert_size_equal(buses.count, 2, "bus count");
    assert_double_equal(buses.items[1].voltage_pu, 1.064, 0.000001, "second bus voltage");

    bus_array_free(&buses);
    assert_size_equal(buses.count, 0, "free resets count");
}

static void test_scenario_init_and_free(void)
{
    Scenario scenario;
    assert_int_equal(scenario_init(&scenario), 0, "scenario init succeeds");
    assert_size_equal(scenario.buses.count, 0, "scenario starts with no buses");
    scenario_free(&scenario);
}

int main(void)
{
    test_bus_array_grows();
    test_scenario_init_and_free();
    return 0;
}
```

- [ x ] **Step 2: Run the failing model test**

Run: `make build/test_model`

Expected: FAIL because `gridval/model.h` does not exist.

- [ ] **Step 3: Add model declarations**

Create `include/gridval/model.h`:

```c
#ifndef GRIDVAL_MODEL_H
#define GRIDVAL_MODEL_H

#include <stddef.h>

#define GRIDVAL_ID_SIZE 64
#define GRIDVAL_SCENARIO_NAME_SIZE 128

typedef struct {
    char id[GRIDVAL_ID_SIZE];
    double voltage_pu;
} Bus;

typedef struct {
    char id[GRIDVAL_ID_SIZE];
    double loading_percent;
} Line;

typedef struct {
    char id[GRIDVAL_ID_SIZE];
    double loading_percent;
} Transformer;

typedef struct {
    Bus *items;
    size_t count;
    size_t capacity;
} BusArray;

typedef struct {
    Line *items;
    size_t count;
    size_t capacity;
} LineArray;

typedef struct {
    Transformer *items;
    size_t count;
    size_t capacity;
} TransformerArray;

typedef struct {
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
```

- [ ] **Step 4: Add dynamic array implementation**

Create `src/model.c` with this pattern for each array type:

```c
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
    array->items = new_items;
    array->capacity = new_capacity;
    return 0;
}

int bus_array_init(BusArray *array)
{
    if (array == NULL) {
        return 1;
    }
    array->items = NULL;
    array->count = 0;
    array->capacity = 0;
    return 0;
}

int bus_array_append(BusArray *array, Bus value)
{
    if (array == NULL) {
        return 1;
    }
    if (array->count == array->capacity && grow_bus_array(array) != 0) {
        return 1;
    }
    array->items[array->count] = value;
    array->count += 1;
    return 0;
}

void bus_array_free(BusArray *array)
{
    if (array == NULL) {
        return;
    }
    free(array->items);
    array->items = NULL;
    array->count = 0;
    array->capacity = 0;
}
```

Then repeat the same ownership pattern for `LineArray` and `TransformerArray`. Implement `scenario_init` by initializing all three arrays and copying `"unnamed"` into `scenario->name`. Implement `scenario_free` by freeing all arrays.

- [ ] **Step 5: Run model test**

Run: `make build/test_model && build/test_model`

Expected: PASS with no output.

- [ ] **Step 6: Teach the ownership rule in a short note**

Add to `docs/engineering-notes.md`:

```markdown
## Dynamic Array Ownership

In M1, a dynamic array struct owns its `items` pointer. The `init` function sets the pointer to `NULL`, `append` grows it with `realloc`, and `free` releases it. Any function that receives `const BusArray *` may read the buses but must not free or mutate them.
```

- [ ] **Step 7: Commit**

Run:

```bash
git add include/gridval/model.h src/model.c tests/test_model.c docs/engineering-notes.md
git commit -m "feat: add scenario model dynamic arrays"
```

---

### Task 3: Validation Limits and Violation Results

**Files:**
- Create: `include/gridval/validation.h`
- Create: `src/validation.c`
- Create: `tests/test_validation.c`

- [ ] **Step 1: Write failing validation tests**

Create `tests/test_validation.c`:

```c
#include "gridval/model.h"
#include "gridval/validation.h"
#include "test_helpers.h"

static ValidationLimits limits(void)
{
    ValidationLimits value = { 0.95, 1.05, 100.0, 100.0 };
    return value;
}

static void test_detects_all_violation_kinds(void)
{
    Scenario scenario;
    ViolationArray violations;
    assert_int_equal(scenario_init(&scenario), 0, "scenario init");
    assert_int_equal(violation_array_init(&violations), 0, "violation array init");

    assert_int_equal(bus_array_append(&scenario.buses, (Bus){ "MT_LOW", 0.930 }), 0, "append low bus");
    assert_int_equal(bus_array_append(&scenario.buses, (Bus){ "MT_HIGH", 1.064 }), 0, "append high bus");
    assert_int_equal(line_array_append(&scenario.lines, (Line){ "L_102", 118.4 }), 0, "append overloaded line");
    assert_int_equal(transformer_array_append(&scenario.transformers, (Transformer){ "TR_01", 103.2 }), 0, "append overloaded transformer");

    assert_int_equal(validate_scenario(&scenario, &(ValidationLimits){ 0.95, 1.05, 100.0, 100.0 }, &violations), 0, "validate");

    assert_size_equal(violations.count, 4, "four violations");
    assert_int_equal((int)violations.items[0].kind, (int)VIOLATION_UNDERVOLTAGE, "first violation kind");
    assert_int_equal((int)violations.items[1].kind, (int)VIOLATION_OVERVOLTAGE, "second violation kind");
    assert_int_equal((int)violations.items[2].kind, (int)VIOLATION_LINE_OVERLOAD, "third violation kind");
    assert_int_equal((int)violations.items[3].kind, (int)VIOLATION_TRANSFORMER_OVERLOAD, "fourth violation kind");

    violation_array_free(&violations);
    scenario_free(&scenario);
}

static void test_inside_limits_passes(void)
{
    Scenario scenario;
    ViolationArray violations;
    ValidationLimits test_limits = limits();
    assert_int_equal(scenario_init(&scenario), 0, "scenario init");
    assert_int_equal(violation_array_init(&violations), 0, "violation array init");

    assert_int_equal(bus_array_append(&scenario.buses, (Bus){ "MT_OK", 1.000 }), 0, "append ok bus");
    assert_int_equal(line_array_append(&scenario.lines, (Line){ "L_OK", 75.0 }), 0, "append ok line");
    assert_int_equal(transformer_array_append(&scenario.transformers, (Transformer){ "TR_OK", 80.0 }), 0, "append ok transformer");

    assert_int_equal(validate_scenario(&scenario, &test_limits, &violations), 0, "validate");
    assert_size_equal(violations.count, 0, "no violations");

    violation_array_free(&violations);
    scenario_free(&scenario);
}

int main(void)
{
    test_detects_all_violation_kinds();
    test_inside_limits_passes();
    return 0;
}
```

- [ ] **Step 2: Run the failing validation test**

Run: `make build/test_validation`

Expected: FAIL because `gridval/validation.h` does not exist.

- [ ] **Step 3: Add validation declarations**

Create `include/gridval/validation.h`:

```c
#ifndef GRIDVAL_VALIDATION_H
#define GRIDVAL_VALIDATION_H

#include "gridval/model.h"

#include <stddef.h>

typedef struct {
    double min_voltage_pu;
    double max_voltage_pu;
    double max_line_loading_percent;
    double max_transformer_loading_percent;
} ValidationLimits;

typedef enum {
    VIOLATION_UNDERVOLTAGE,
    VIOLATION_OVERVOLTAGE,
    VIOLATION_LINE_OVERLOAD,
    VIOLATION_TRANSFORMER_OVERLOAD
} ViolationKind;

typedef struct {
    ViolationKind kind;
    char element_id[GRIDVAL_ID_SIZE];
    double observed_value;
    double limit_value;
} Violation;

typedef struct {
    Violation *items;
    size_t count;
    size_t capacity;
} ViolationArray;

int violation_array_init(ViolationArray *array);
int violation_array_append(ViolationArray *array, Violation value);
void violation_array_free(ViolationArray *array);

int validate_scenario(
    const Scenario *scenario,
    const ValidationLimits *limits,
    ViolationArray *violations
);

#endif
```

- [ ] **Step 4: Implement validation**

Create `src/validation.c`. Use the same dynamic-array pattern from `src/model.c` for `ViolationArray`, then implement:

```c
static int append_violation(
    ViolationArray *violations,
    ViolationKind kind,
    const char *element_id,
    double observed_value,
    double limit_value
)
{
    Violation violation;
    violation.kind = kind;
    snprintf(violation.element_id, sizeof(violation.element_id), "%s", element_id);
    violation.observed_value = observed_value;
    violation.limit_value = limit_value;
    return violation_array_append(violations, violation);
}

int validate_scenario(
    const Scenario *scenario,
    const ValidationLimits *limits,
    ViolationArray *violations
)
{
    if (scenario == NULL || limits == NULL || violations == NULL) {
        return 1;
    }

    for (size_t i = 0; i < scenario->buses.count; i += 1) {
        const Bus *bus = &scenario->buses.items[i];
        if (bus->voltage_pu < limits->min_voltage_pu) {
            if (append_violation(violations, VIOLATION_UNDERVOLTAGE, bus->id, bus->voltage_pu, limits->min_voltage_pu) != 0) {
                return 1;
            }
        }
        if (bus->voltage_pu > limits->max_voltage_pu) {
            if (append_violation(violations, VIOLATION_OVERVOLTAGE, bus->id, bus->voltage_pu, limits->max_voltage_pu) != 0) {
                return 1;
            }
        }
    }

    for (size_t i = 0; i < scenario->lines.count; i += 1) {
        const Line *line = &scenario->lines.items[i];
        if (line->loading_percent > limits->max_line_loading_percent) {
            if (append_violation(violations, VIOLATION_LINE_OVERLOAD, line->id, line->loading_percent, limits->max_line_loading_percent) != 0) {
                return 1;
            }
        }
    }

    for (size_t i = 0; i < scenario->transformers.count; i += 1) {
        const Transformer *transformer = &scenario->transformers.items[i];
        if (transformer->loading_percent > limits->max_transformer_loading_percent) {
            if (append_violation(violations, VIOLATION_TRANSFORMER_OVERLOAD, transformer->id, transformer->loading_percent, limits->max_transformer_loading_percent) != 0) {
                return 1;
            }
        }
    }

    return 0;
}
```

Include `<stdio.h>`, `<stdlib.h>`, and `<string.h>` at the top of `src/validation.c`.

- [ ] **Step 5: Run validation tests**

Run: `make build/test_validation && build/test_validation`

Expected: PASS with no output.

- [ ] **Step 6: Commit**

Run:

```bash
git add include/gridval/validation.h src/validation.c tests/test_validation.c
git commit -m "feat: validate voltage and loading limits"
```

---

### Task 4: Config Parser

**Files:**
- Create: `include/gridval/config.h`
- Create: `src/config.c`
- Create: `tests/test_config.c`
- Create: `tests/fixtures/config_valid.ini`
- Create: `tests/fixtures/config_invalid.ini`

- [ ] **Step 1: Write config fixtures**

Create `tests/fixtures/config_valid.ini`:

```ini
min_voltage_pu=0.95
max_voltage_pu=1.05
max_line_loading_percent=100.0
max_transformer_loading_percent=100.0
```

Create `tests/fixtures/config_invalid.ini`:

```ini
min_voltage_pu=not-a-number
max_voltage_pu=1.05
max_line_loading_percent=100.0
max_transformer_loading_percent=100.0
```

- [ ] **Step 2: Write failing config tests**

Create `tests/test_config.c`:

```c
#include "gridval/config.h"
#include "test_helpers.h"

int main(void)
{
    ValidationLimits limits;
    char error[256];

    assert_int_equal(load_validation_limits("tests/fixtures/config_valid.ini", &limits, error, sizeof(error)), 0, "valid config loads");
    assert_double_equal(limits.min_voltage_pu, 0.95, 0.000001, "min voltage");
    assert_double_equal(limits.max_voltage_pu, 1.05, 0.000001, "max voltage");

    assert_int_equal(load_validation_limits("tests/fixtures/config_invalid.ini", &limits, error, sizeof(error)), 1, "invalid config fails");
    assert_string_contains(error, "min_voltage_pu", "error names invalid key");

    assert_int_equal(load_validation_limits("tests/fixtures/missing.ini", &limits, error, sizeof(error)), 1, "missing config fails");
    assert_string_contains(error, "open", "missing file error");

    return 0;
}
```

- [ ] **Step 3: Run failing config test**

Run: `make build/test_config`

Expected: FAIL because `gridval/config.h` does not exist.

- [ ] **Step 4: Add config API**

Create `include/gridval/config.h`:

```c
#ifndef GRIDVAL_CONFIG_H
#define GRIDVAL_CONFIG_H

#include "gridval/validation.h"

#include <stddef.h>

int load_validation_limits(
    const char *path,
    ValidationLimits *limits,
    char *error,
    size_t error_size
);

#endif
```

- [ ] **Step 5: Implement config parsing**

Create `src/config.c` using `fopen`, `fgets`, `strchr`, and `strtod`. The core parse helper should follow this shape:

```c
static int parse_double_value(const char *key, const char *text, double *out, char *error, size_t error_size)
{
    char *end = NULL;
    double value = strtod(text, &end);
    if (end == text || (*end != '\0' && *end != '\n')) {
        snprintf(error, error_size, "invalid numeric value for %s", key);
        return 1;
    }
    *out = value;
    return 0;
}
```

`load_validation_limits` should initialize all limits to `0.0`, set a seen flag for each required key, parse each line as `key=value`, and fail if any required key is missing.

- [ ] **Step 6: Run config tests**

Run: `make build/test_config && build/test_config`

Expected: PASS with no output.

- [ ] **Step 7: Commit**

Run:

```bash
git add include/gridval/config.h src/config.c tests/test_config.c tests/fixtures/config_valid.ini tests/fixtures/config_invalid.ini
git commit -m "feat: load validation limits from config"
```

---

### Task 5: Scenario CSV Loader

**Files:**
- Create: `include/gridval/csv.h`
- Create: `src/csv.c`
- Create: `tests/test_csv.c`
- Create: `tests/fixtures/simple_valid/buses.csv`
- Create: `tests/fixtures/simple_valid/lines.csv`
- Create: `tests/fixtures/simple_valid/transformers.csv`
- Create: `tests/fixtures/simple_valid/summary.csv`
- Create: `tests/fixtures/malformed/buses.csv`

- [ ] **Step 1: Write CSV fixtures**

Create `tests/fixtures/simple_valid/buses.csv`:

```csv
id,voltage_pu
MT_001,1.000
MT_032,1.064
```

Create `tests/fixtures/simple_valid/lines.csv`:

```csv
id,loading_percent
L_102,118.4
```

Create `tests/fixtures/simple_valid/transformers.csv`:

```csv
id,loading_percent
TR_01,103.2
```

Create `tests/fixtures/simple_valid/summary.csv`:

```csv
key,value
scenario_name,with_pv_no_reinforcement
```

Create `tests/fixtures/malformed/buses.csv`:

```csv
id,voltage_pu
MT_BAD,abc
```

- [ ] **Step 2: Write failing CSV tests**

Create `tests/test_csv.c`:

```c
#include "gridval/csv.h"
#include "test_helpers.h"

int main(void)
{
    Scenario scenario;
    char error[256];

    assert_int_equal(scenario_init(&scenario), 0, "scenario init");
    assert_int_equal(load_scenario("tests/fixtures/simple_valid", &scenario, error, sizeof(error)), 0, "load valid scenario");
    assert_string_contains(scenario.name, "with_pv_no_reinforcement", "scenario name");
    assert_size_equal(scenario.buses.count, 2, "bus count");
    assert_size_equal(scenario.lines.count, 1, "line count");
    assert_size_equal(scenario.transformers.count, 1, "transformer count");
    scenario_free(&scenario);

    assert_int_equal(scenario_init(&scenario), 0, "scenario init for malformed");
    assert_int_equal(load_buses_csv("tests/fixtures/malformed/buses.csv", &scenario.buses, error, sizeof(error)), 1, "malformed bus CSV fails");
    assert_string_contains(error, "voltage_pu", "malformed bus error");
    scenario_free(&scenario);

    return 0;
}
```

- [ ] **Step 3: Run failing CSV test**

Run: `make build/test_csv`

Expected: FAIL because `gridval/csv.h` does not exist.

- [ ] **Step 4: Add CSV API**

Create `include/gridval/csv.h`:

```c
#ifndef GRIDVAL_CSV_H
#define GRIDVAL_CSV_H

#include "gridval/model.h"

#include <stddef.h>

int load_buses_csv(const char *path, BusArray *buses, char *error, size_t error_size);
int load_lines_csv(const char *path, LineArray *lines, char *error, size_t error_size);
int load_transformers_csv(const char *path, TransformerArray *transformers, char *error, size_t error_size);
int load_summary_csv(const char *path, Scenario *scenario, char *error, size_t error_size);
int load_scenario(const char *path, Scenario *scenario, char *error, size_t error_size);

#endif
```

- [ ] **Step 5: Implement CSV parsing**

Create `src/csv.c`. Use fixed line buffers for M1:

```c
#define LINE_BUFFER_SIZE 512
#define PATH_BUFFER_SIZE 512
```

Use `snprintf` to build paths such as:

```c
snprintf(file_path, sizeof(file_path), "%s/buses.csv", path);
```

For each data row, split the first comma with `strchr`, terminate it with `'\0'`, parse the numeric field with `strtod`, and append the parsed record to the target dynamic array. `load_scenario` should call the four file-specific loaders.

- [ ] **Step 6: Run CSV tests**

Run: `make build/test_csv && build/test_csv`

Expected: PASS with no output.

- [ ] **Step 7: Commit**

Run:

```bash
git add include/gridval/csv.h src/csv.c tests/test_csv.c tests/fixtures/simple_valid tests/fixtures/malformed
git commit -m "feat: load scenario CSV files"
```

---

### Task 6: Markdown Report Writer

**Files:**
- Create: `include/gridval/report.h`
- Create: `src/report.c`
- Create: `tests/test_report.c`

- [ ] **Step 1: Write failing report test**

Create `tests/test_report.c`:

```c
#include "gridval/model.h"
#include "gridval/report.h"
#include "gridval/validation.h"
#include "test_helpers.h"

#include <stdio.h>

int main(void)
{
    Scenario scenario;
    ViolationArray violations;
    char buffer[4096];

    assert_int_equal(scenario_init(&scenario), 0, "scenario init");
    assert_int_equal(violation_array_init(&violations), 0, "violation array init");

    snprintf(scenario.name, sizeof(scenario.name), "%s", "with_pv_no_reinforcement");
    assert_int_equal(violation_array_append(&violations, (Violation){ VIOLATION_OVERVOLTAGE, "MT_032", 1.064, 1.050 }), 0, "append voltage violation");

    assert_int_equal(write_validation_report("build/test_report.md", &scenario, &violations), 0, "write report");

    FILE *file = fopen("build/test_report.md", "r");
    assert_int_equal(file != NULL, 1, "open generated report");
    size_t bytes = fread(buffer, 1, sizeof(buffer) - 1, file);
    fclose(file);
    buffer[bytes] = '\0';

    assert_string_contains(buffer, "Scenario Validation Report", "report title");
    assert_string_contains(buffer, "Overall result: FAIL", "fail result");
    assert_string_contains(buffer, "MT_032", "violation element");

    violation_array_free(&violations);
    scenario_free(&scenario);
    return 0;
}
```

- [ ] **Step 2: Run failing report test**

Run: `make build/test_report`

Expected: FAIL because `gridval/report.h` does not exist.

- [ ] **Step 3: Add report API**

Create `include/gridval/report.h`:

```c
#ifndef GRIDVAL_REPORT_H
#define GRIDVAL_REPORT_H

#include "gridval/model.h"
#include "gridval/validation.h"

int write_validation_report(
    const char *path,
    const Scenario *scenario,
    const ViolationArray *violations
);

#endif
```

- [ ] **Step 4: Implement report writer**

Create `src/report.c`. Open output with `fopen(path, "w")`, write the title, scenario name, overall result, and three sections. Use helper functions to print only matching violation kinds:

```c
static const char *overall_result(const ViolationArray *violations)
{
    return violations->count == 0 ? "PASS" : "FAIL";
}
```

Voltage section prints under/overvoltage. Line section prints line overloads. Transformer section prints transformer overloads. Each empty section prints `None`.

- [ ] **Step 5: Run report tests**

Run: `make build/test_report && build/test_report`

Expected: PASS with no output and `build/test_report.md` generated.

- [ ] **Step 6: Commit**

Run:

```bash
git add include/gridval/report.h src/report.c tests/test_report.c
git commit -m "feat: generate validation markdown report"
```

---

### Task 7: CLI and Example Scenario

**Files:**
- Create: `src/main.c`
- Create: `examples/config.ini`
- Create: `examples/scenario_with_pv/buses.csv`
- Create: `examples/scenario_with_pv/lines.csv`
- Create: `examples/scenario_with_pv/transformers.csv`
- Create: `examples/scenario_with_pv/summary.csv`

- [ ] **Step 1: Create the example scenario**

Create `examples/config.ini`:

```ini
min_voltage_pu=0.95
max_voltage_pu=1.05
max_line_loading_percent=100.0
max_transformer_loading_percent=100.0
```

Create `examples/scenario_with_pv/buses.csv`:

```csv
id,voltage_pu
MT_001,1.000
MT_032,1.064
MT_041,1.071
```

Create `examples/scenario_with_pv/lines.csv`:

```csv
id,loading_percent
L_102,118.4
L_205,72.0
```

Create `examples/scenario_with_pv/transformers.csv`:

```csv
id,loading_percent
TR_01,103.2
```

Create `examples/scenario_with_pv/summary.csv`:

```csv
key,value
scenario_name,with_pv_no_reinforcement
```

- [ ] **Step 2: Run CLI before implementation**

Run:

```bash
make
build/gridval validate --scenario examples/scenario_with_pv --config examples/config.ini --out report.md
```

Expected: FAIL because `src/main.c` is not implemented.

- [ ] **Step 3: Implement CLI orchestration**

Create `src/main.c`:

```c
#include "gridval/config.h"
#include "gridval/csv.h"
#include "gridval/model.h"
#include "gridval/report.h"
#include "gridval/validation.h"

#include <stdio.h>
#include <string.h>

static int parse_validate_args(int argc, char **argv, const char **scenario_path, const char **config_path, const char **out_path)
{
    for (int i = 2; i < argc; i += 1) {
        if (strcmp(argv[i], "--scenario") == 0 && i + 1 < argc) {
            *scenario_path = argv[i + 1];
            i += 1;
        } else if (strcmp(argv[i], "--config") == 0 && i + 1 < argc) {
            *config_path = argv[i + 1];
            i += 1;
        } else if (strcmp(argv[i], "--out") == 0 && i + 1 < argc) {
            *out_path = argv[i + 1];
            i += 1;
        } else {
            return 1;
        }
    }
    return *scenario_path != NULL && *config_path != NULL && *out_path != NULL ? 0 : 1;
}

int main(int argc, char **argv)
{
    const char *scenario_path = NULL;
    const char *config_path = NULL;
    const char *out_path = NULL;
    char error[256];
    ValidationLimits limits;
    Scenario scenario;
    ViolationArray violations;

    if (argc < 2 || strcmp(argv[1], "validate") != 0) {
        fprintf(stderr, "usage: gridval validate --scenario PATH --config PATH --out PATH\n");
        return 1;
    }

    if (parse_validate_args(argc, argv, &scenario_path, &config_path, &out_path) != 0) {
        fprintf(stderr, "usage: gridval validate --scenario PATH --config PATH --out PATH\n");
        return 1;
    }

    if (scenario_init(&scenario) != 0 || violation_array_init(&violations) != 0) {
        fprintf(stderr, "error: failed to initialize memory\n");
        return 1;
    }

    if (load_validation_limits(config_path, &limits, error, sizeof(error)) != 0) {
        fprintf(stderr, "error: %s\n", error);
        scenario_free(&scenario);
        violation_array_free(&violations);
        return 1;
    }

    if (load_scenario(scenario_path, &scenario, error, sizeof(error)) != 0) {
        fprintf(stderr, "error: %s\n", error);
        scenario_free(&scenario);
        violation_array_free(&violations);
        return 1;
    }

    if (validate_scenario(&scenario, &limits, &violations) != 0) {
        fprintf(stderr, "error: validation failed\n");
        scenario_free(&scenario);
        violation_array_free(&violations);
        return 1;
    }

    if (write_validation_report(out_path, &scenario, &violations) != 0) {
        fprintf(stderr, "error: failed to write report\n");
        scenario_free(&scenario);
        violation_array_free(&violations);
        return 1;
    }

    printf("Wrote validation report to %s\n", out_path);
    scenario_free(&scenario);
    violation_array_free(&violations);
    return 0;
}
```

- [ ] **Step 4: Run full CLI example**

Run:

```bash
make
build/gridval validate --scenario examples/scenario_with_pv --config examples/config.ini --out report.md
```

Expected: PASS and output includes:

```text
Wrote validation report to report.md
```

- [ ] **Step 5: Inspect generated report**

Run: `sed -n '1,120p' report.md`

Expected report includes:

```text
Overall result: FAIL
MT_032
MT_041
L_102
TR_01
```

- [ ] **Step 6: Commit**

Run:

```bash
git add src/main.c examples/config.ini examples/scenario_with_pv
git commit -m "feat: add validate CLI example"
```

---

### Task 8: M1 Documentation

**Files:**
- Modify: `README.md`
- Create: `docs/scenario-format.md`
- Create: `docs/validation-rules.md`
- Modify: `docs/power-flow-learning.md`

- [ ] **Step 1: Update README**

Replace `README.md` with sections covering:

```markdown
# C Grid Connection Reinforcement Validator

`gridval` is a C17 command-line tool for validating exported distribution-grid study scenarios for Brazilian solar plant connection studies.

## Current Milestone

M1 validates one scenario from CSV files and generates a Markdown report. It does not run a power-flow calculation.

## Build

```bash
make
```

## Test

```bash
make test
```

## Run Example

```bash
build/gridval validate \
  --scenario examples/scenario_with_pv \
  --config examples/config.ini \
  --out report.md
```

## Supported Checks

- bus voltage below configured minimum
- bus voltage above configured maximum
- line loading above configured maximum
- transformer loading above configured maximum

## Not Supported Yet

- scenario comparison
- power-flow calculations
- OpenDSS/DSS C-API integration
- automatic reinforcement recommendation
```

- [ ] **Step 2: Add scenario format docs**

Create `docs/scenario-format.md` with the CSV and config formats from the approved design spec.

- [ ] **Step 3: Add validation rule docs**

Create `docs/validation-rules.md` explaining each rule:

```markdown
# Validation Rules

M1 applies configured engineering limits to exported study results.

## Undervoltage

A bus violates the minimum voltage rule when `voltage_pu < min_voltage_pu`.

## Overvoltage

A bus violates the maximum voltage rule when `voltage_pu > max_voltage_pu`.

## Line Overload

A line violates the loading rule when `loading_percent > max_line_loading_percent`.

## Transformer Overload

A transformer violates the loading rule when `loading_percent > max_transformer_loading_percent`.
```

- [ ] **Step 4: Add learning note**

Add to `docs/power-flow-learning.md`:

```markdown
## M1: Validation Before Simulation

M1 does not calculate voltages or currents. It assumes another study tool has already produced voltage magnitudes and loading percentages. `gridval` checks those exported results against configured limits.
```

- [ ] **Step 5: Run final docs-adjacent verification**

Run:

```bash
make test
make
build/gridval validate --scenario examples/scenario_with_pv --config examples/config.ini --out report.md
```

Expected: all tests pass, CLI writes `report.md`.

- [ ] **Step 6: Commit**

Run:

```bash
git add README.md docs/scenario-format.md docs/validation-rules.md docs/power-flow-learning.md
git commit -m "docs: document m1 validator usage"
```

---

## Final Verification

Run:

```bash
make clean
make test
make
build/gridval validate --scenario examples/scenario_with_pv --config examples/config.ini --out report.md
sed -n '1,120p' report.md
git status --short
```

Expected:

- `make test` exits with status `0`
- `make` exits with status `0`
- CLI prints `Wrote validation report to report.md`
- report includes voltage, line, and transformer violations
- `git status --short` shows only expected uncommitted generated files, especially ignored `report.md` and `build/`

## Self-Review Notes

- Spec coverage: This plan covers build, tests, dynamic arrays, validation, config loading, CSV loading, report generation, CLI usage, examples, and M1 docs.
- Scope check: This plan intentionally excludes scenario comparison and power-flow calculations.
- Type consistency: `ValidationLimits`, `ViolationArray`, `Scenario`, and the dynamic array APIs are introduced before they are consumed by later tasks.
