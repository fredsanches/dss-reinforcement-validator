# M1 Single-Scenario Validator Design

## Purpose

M1 builds the first useful version of `dss-reinforcement-validator`: a C17 command-line tool that reads one exported grid-study scenario from CSV files, validates voltage and loading constraints, and writes a Markdown report.

This milestone is a validator, not a simulator. It does not calculate power flow. It checks study outputs that already contain voltage magnitudes and element loading percentages.

## User Outcome

The user can run:

```bash
gridval validate \
  --scenario examples/scenario_with_pv \
  --config examples/config.ini \
  --out report.md
```

The tool reads:

```text
examples/scenario_with_pv/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv
```

It writes `report.md` with:

- scenario name
- voltage violations
- line loading violations
- transformer loading violations
- overall pass/fail summary

## Scope

M1 includes:

- reading one scenario
- reading configurable limits
- validating bus voltage below minimum
- validating bus voltage above maximum
- validating line loading above maximum
- validating transformer loading above maximum
- generating one Markdown report
- clear error messages for missing or malformed files
- tests for validation logic and core parsing/reporting behavior

M1 excludes:

- scenario comparison
- power-flow calculations
- OpenDSS or DSS C-API integration
- Brazilian regulatory hard-coding
- optimization or reinforcement recommendation logic

## C Learning Goals

M1 intentionally introduces production-shaped C concepts early:

- `struct` for domain records such as buses, lines, transformers, limits, and violations
- `enum` for validation status and violation kind
- header/source separation with declarations in `include/gridval/` and implementations in `src/`
- `const` correctness for functions that inspect data without mutating it
- dynamic arrays using `malloc`, `realloc`, and `free`
- ownership rules for heap-allocated memory
- simple file I/O with `fopen`, `fgets`, and `fclose`
- simple CSV parsing using standard C library functions
- deterministic tests built as small C executables

## Power-Systems Learning Goals

M1 focuses on interpreting exported study results:

- bus voltage magnitude in per-unit
- voltage lower and upper limits
- line thermal loading percentage
- transformer loading percentage
- constraint violation as technical evidence
- Markdown report structure for engineering review

## Architecture

The project will use small modules with clear responsibilities:

```text
include/gridval/
  model.h
  config.h
  validation.h
  csv.h
  report.h

src/
  main.c
  model.c
  config.c
  validation.c
  csv.c
  report.c

tests/
  test_validation.c
  test_csv.c
  test_report.c

examples/
  config.ini
  scenario_with_pv/
    buses.csv
    lines.csv
    transformers.csv
    summary.csv
```

`model.h` owns the core domain structs and dynamic array types.

`config.h` owns the validation limits loaded from `config.ini`.

`validation.h` owns pure validation functions. These functions inspect a loaded scenario and produce violations. They should not read files or write reports.

`csv.h` owns loading CSV files into the scenario model.

`report.h` owns writing Markdown output from validation results.

`main.c` owns command-line argument parsing and orchestration.

## Data Model

The first domain records should be intentionally small:

```c
typedef struct {
    char id[64];
    double voltage_pu;
} Bus;

typedef struct {
    char id[64];
    double loading_percent;
} Line;

typedef struct {
    char id[64];
    double loading_percent;
} Transformer;
```

These are structs because each record groups related fields that travel together. A bus is not just a voltage; it is an identified electrical node with a measured voltage. A line or transformer is not just a number; it is a named element with a loading percentage.

The first dynamic array pattern should look like this:

```c
typedef struct {
    Bus *items;
    size_t count;
    size_t capacity;
} BusArray;
```

`items` points to heap memory. `count` says how many valid `Bus` values are stored. `capacity` says how many values fit before the array must grow.

The same pattern applies to lines, transformers, and violations.

## Heap Allocation and Ownership

Dynamic arrays are used because real exported studies may contain an unknown number of buses, lines, and transformers. A fixed array like `Bus buses[100]` would force the program to guess a maximum size.

The dynamic array lifecycle is:

```text
init -> append many times -> free
```

For example:

```c
BusArray buses;
bus_array_init(&buses);
bus_array_append(&buses, bus);
bus_array_free(&buses);
```

Ownership rule:

- `BusArray` owns its `items` pointer.
- The caller that initializes a `BusArray` is responsible for eventually calling `bus_array_free`.
- Validation functions may read a `const BusArray *`, but they do not own it and must not free it.
- CSV loading functions mutate arrays by appending parsed records.
- Report functions read validation results and do not mutate them.

`malloc` asks the heap for a new memory block.

`realloc` grows or shrinks an existing heap block.

`free` releases heap memory when the array is no longer needed.

Every successful allocation must have a clear cleanup path.

## Validation Design

Configuration limits are loaded into:

```c
typedef struct {
    double min_voltage_pu;
    double max_voltage_pu;
    double max_line_loading_percent;
    double max_transformer_loading_percent;
} ValidationLimits;
```

Violations are represented with an enum and a struct:

```c
typedef enum {
    VIOLATION_UNDERVOLTAGE,
    VIOLATION_OVERVOLTAGE,
    VIOLATION_LINE_OVERLOAD,
    VIOLATION_TRANSFORMER_OVERLOAD
} ViolationKind;

typedef struct {
    ViolationKind kind;
    char element_id[64];
    double observed_value;
    double limit_value;
} Violation;
```

An enum is used because the violation kind is one of a known set of named cases. This is clearer and safer than passing strings such as `"overvoltage"` through the program.

Validation functions should be deterministic and easy to test:

```c
int validate_scenario(
    const Scenario *scenario,
    const ValidationLimits *limits,
    ViolationArray *violations
);
```

`scenario` and `limits` are `const` because validation reads them but does not change them. `violations` is not `const` because the function appends validation findings to it.

## CSV Format

M1 uses simple CSV files with headers.

`buses.csv`:

```csv
id,voltage_pu
MT_001,1.000
MT_032,1.064
```

`lines.csv`:

```csv
id,loading_percent
L_102,118.4
```

`transformers.csv`:

```csv
id,loading_percent
TR_01,103.2
```

`summary.csv`:

```csv
key,value
scenario_name,with_pv_no_reinforcement
```

M1 assumes simple fields without quoted commas. If a row is missing a required field or has a non-numeric value where a number is required, the loader returns an error.

## Config Format

M1 uses a simple `key=value` file:

```ini
min_voltage_pu=0.95
max_voltage_pu=1.05
max_line_loading_percent=100.0
max_transformer_loading_percent=100.0
```

Hard-coded regulatory limits are avoided. The example config can use common study limits, but the code treats them as user configuration.

## Report Format

The Markdown report should be plain and technical:

```markdown
# Scenario Validation Report

Scenario: with_pv_no_reinforcement

Overall result: FAIL

## Voltage Violations

- MT_032: 1.064 pu above maximum 1.050 pu

## Line Loading Violations

- L_102: 118.4% above maximum 100.0%

## Transformer Loading Violations

- TR_01: 103.2% above maximum 100.0%
```

If a category has no violations, the report writes `None`.

## Error Handling

M1 uses explicit status codes and human-readable error messages.

Functions that can fail should return `int`, where `0` means success and nonzero means failure. The caller provides an error buffer when useful:

```c
int load_scenario(const char *path, Scenario *scenario, char *error, size_t error_size);
```

Pointers may be `NULL` only where documented. Public functions should check for invalid `NULL` inputs and return an error rather than crashing.

## Testing Strategy

Tests should be small C programs compiled by the Makefile.

Initial tests:

- validation detects undervoltage
- validation detects overvoltage
- validation detects line overload
- validation detects transformer overload
- validation passes when all values are inside limits
- CSV parser loads simple fixture files
- malformed numeric fields produce a clear error
- report generation writes expected category headings and pass/fail result

Validation tests should come first because they do not need file I/O. They can build scenarios directly in memory, which makes the C structs and dynamic arrays easier to learn before parsing is added.

## Build Strategy

Use a simple Makefile with `clang` and strict warnings:

```text
-std=c17 -Wall -Wextra -Wpedantic -Wconversion -Wshadow -g -O0
```

Targets:

- `make` builds `build/gridval`
- `make test` builds and runs tests
- `make clean` removes build outputs

No external dependencies are needed for M1.

## Completion Criteria

M1 is complete when:

- `make` builds the CLI
- `make test` runs validation and parser/report tests
- the sample scenario can be validated from the command line
- voltage violations are detected correctly
- line loading violations are detected correctly
- transformer loading violations are detected correctly
- a Markdown report is generated
- README explains build, test, and example usage
- docs explain scenario format and validation rules

## Open Notes

The repository currently appears not to be initialized as a Git repository from the shell. The Superpowers workflow normally asks for spec commits, but this project will skip commits until Git is available or initialized by the user.
