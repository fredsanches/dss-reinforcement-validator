# Roadmap

This document defines the execution roadmap for `dss-reinforcement-validator`.

The roadmap is organized into milestones. Each milestone must produce a useful engineering result while also teaching specific C programming concepts and power-systems concepts.

The project should move from simple validation to scenario comparison, then to educational power-flow calculations, and only later to DSS C-API/OpenDSS integration.

---

## Roadmap philosophy

The project must avoid trying to solve everything at once.

The correct order is:

1. Validate exported study data.
2. Compare scenarios.
3. Learn and implement simplified power-flow calculations.
4. Integrate with DSS C-API/OpenDSS.
5. Generate stronger Brazilian grid-connection technical reports.

The first useful product is a validator, not a simulator.

---

# M1 — Single-scenario validator

## Goal

Build a C command-line tool that reads one grid-study scenario from CSV files and produces a Markdown validation report.

This milestone does not perform power-flow calculations.

## Engineering purpose

The user should be able to inspect one scenario and answer:

> Does this scenario violate voltage or loading constraints?

## Example command

```bash
gridval validate \
  --scenario examples/scenario_with_pv \
  --config examples/config.ini \
  --out report.md
```

## Expected input files

```text
scenario_with_pv/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv
```

## Expected output

```text
report.md
```

The report should include:

* scenario name
* voltage violations
* line loading violations
* transformer loading violations
* simple summary of whether the scenario passed or failed

## Minimum features

* Read `buses.csv`
* Read `lines.csv`
* Read `transformers.csv`
* Read configuration limits
* Validate minimum bus voltage
* Validate maximum bus voltage
* Validate maximum line loading
* Validate maximum transformer loading
* Generate a Markdown report
* Provide clear error messages for missing or malformed files

## Suggested C concepts

* project structure
* header files
* source files
* structs
* enums
* arrays
* pointers
* `const` correctness
* file I/O
* string handling
* basic error handling
* command-line arguments
* unit tests

## Suggested power-systems concepts

* bus voltage magnitude
* per-unit voltage
* voltage lower limit
* voltage upper limit
* line loading percentage
* transformer loading percentage
* constraint violation
* technical report structure

## Completion criteria

M1 is complete when:

* the project builds from the command line
* the CLI can read a sample scenario
* voltage violations are detected correctly
* line loading violations are detected correctly
* transformer loading violations are detected correctly
* a Markdown report is generated
* validation logic has tests
* README explains how to build, test, and run the example

---

# M2 — Scenario comparison

## Goal

Compare multiple scenarios to understand what changed between the base case, requested solar connection case, and utility reinforcement case.

## Engineering purpose

The user should be able to answer:

> Which violations appeared after the solar plant connection, and which violations were solved by the utility reinforcement?

## Example command

```bash
gridval compare \
  --base examples/scenario_base \
  --requested examples/scenario_with_pv \
  --utility examples/scenario_with_reinforcement \
  --config examples/config.ini \
  --out comparison.md
```

## Expected input files

```text
scenario_base/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv

scenario_with_pv/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv

scenario_with_reinforcement/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv
```

## Expected output

```text
comparison.md
```

The report should include:

* violations in the base scenario
* violations in the requested-generation scenario
* violations in the utility-reinforcement scenario
* new violations caused by the solar plant connection
* violations removed by the reinforcement
* elements that appear to be limiting the connection
* observations that may support a technical challenge

## Minimum features

* Load multiple scenarios
* Compare bus voltages across scenarios
* Compare line loading across scenarios
* Compare transformer loading across scenarios
* Identify new violations
* Identify solved violations
* Identify persistent violations
* Generate a comparison report

## Suggested C concepts

* dynamic arrays
* ownership rules
* memory allocation
* memory cleanup
* searching
* sorting
* string keys
* cross-file data modeling
* modular report generation
* stronger test fixtures

## Suggested power-systems concepts

* base case
* connection case
* reinforcement case
* limiting element
* technical justification
* before/after comparison
* reinforcement effectiveness

## Completion criteria

M2 is complete when:

* the CLI compares at least three scenarios
* the tool identifies new violations correctly
* the tool identifies solved violations correctly
* the tool identifies persistent violations correctly
* the report highlights limiting elements
* tests cover scenario comparison logic
* example scenarios are documented

---

# M3 — Simplified radial power-flow engine

## Goal

Implement a simplified educational power-flow engine for a balanced radial medium-voltage feeder.

This milestone is mainly for learning. It should not try to replace OpenDSS.

## Engineering purpose

The user should rebuild the mathematical foundation behind the validation results.

The user should be able to answer:

> Given a simplified feeder, loads, generation, and line impedances, what are the approximate bus voltages and line currents?

## Initial assumptions

The first solver should assume:

* balanced three-phase equivalent
* radial feeder
* single source bus
* PQ loads
* solar plant modeled as negative load or controlled injection
* fixed nominal voltage base
* line impedance known
* no voltage regulators
* no capacitor banks
* no protection modeling
* no unbalanced phase modeling

## Recommended method

Start with backward/forward sweep.

Avoid Newton-Raphson at first.

## Minimum features

* Read a simple feeder model
* Build parent/child feeder topology
* Calculate load and generation injections
* Perform backward current accumulation
* Perform forward voltage update
* Iterate until convergence
* Report bus voltages
* Report line currents
* Report loading estimates
* Validate voltage and loading constraints using the existing validation engine

## Suggested C concepts

* complex numbers
* graph/tree representation
* arrays of structs
* dynamic memory
* iterative algorithms
* numerical tolerances
* convergence criteria
* function decomposition
* debug logging
* comparison against known examples

## Suggested power-systems concepts

* per-unit system
* apparent power
* complex power
* line impedance
* voltage drop
* current flow
* radial feeder topology
* convergence tolerance
* slack/source bus
* PQ bus
* generation as negative load

## Completion criteria

M3 is complete when:

* the solver runs on a small radial feeder
* the solver converges for a deterministic example
* bus voltages are reported
* line currents are reported
* voltage/loading validations reuse the M1 validation logic
* tests cover at least one simple feeder case
* documentation explains the equations used

---

# M4 — DSS C-API / OpenDSS integration

## Goal

Integrate with DSS C-API or OpenDSS so the tool can run external power-flow studies and validate the exported results automatically.

## Engineering purpose

The user should be able to answer:

> Can this tool run or consume OpenDSS-based scenarios and generate the same validation reports automatically?

## Minimum features

* Compile or load an OpenDSS model
* Run a base scenario
* Run a requested-generation scenario
* Run a reinforcement scenario
* Export bus voltage results
* Export line loading results
* Export transformer loading results
* Reuse the existing validation engine
* Generate the same Markdown reports from DSS results

## Suggested C concepts

* external C libraries
* build-system configuration
* linking
* include paths
* API wrappers
* error propagation
* abstraction boundaries
* integration testing

## Suggested power-systems concepts

* OpenDSS model structure
* circuit compilation
* solution modes
* monitors/meters/exports
* comparison between educational solver and external simulator
* simulator limitations and assumptions

## Completion criteria

M4 is complete when:

* the project builds with DSS C-API support
* an example OpenDSS scenario can be executed
* results can be converted into the internal scenario format
* validation reports are generated from DSS results
* documentation explains how to install and configure the dependency

---

# M5 — Brazilian grid-connection technical report template

## Goal

Generate a stronger technical report format focused on Brazilian solar grid-connection studies and Orçamento de Conexão discussions.

## Engineering purpose

The user should be able to produce a report that helps review or challenge a utility’s proposed reinforcement.

## Minimum features

* Executive summary
* Input scenario summary
* Voltage violation table
* Loading violation table
* Scenario comparison table
* Limiting-element discussion
* Reinforcement-effectiveness discussion
* List of recommended additional studies
* Configurable assumptions and limits

## Suggested C concepts

* report templates
* string builders or buffered writing
* formatting functions
* table generation
* separation between data and presentation
* regression tests for generated reports

## Suggested power-systems concepts

* technical evidence
* reinforcement justification
* alternative scenario analysis
* voltage compliance
* thermal compliance
* reverse power flow discussion
* study assumptions

## Completion criteria

M5 is complete when:

* the report is useful to an engineer reviewing a grid-connection study
* report sections are configurable
* generated Markdown is readable
* example reports are included in the repository
* documentation explains what the report can and cannot conclude

---

# Future ideas

These ideas should not distract from the main roadmap.

Possible future modules:

* performance ratio analysis
* solar generation vs irradiance analysis
* energy revenue and credit allocation analysis
* Python reference scripts
* CSV-to-DSS model generation
* automated comparison against utility-provided study tables
* HTML or PDF report generation
* sensitivity studies for plant size and power factor
* hosting capacity estimation

---

# Current milestone

Current milestone:

```text
M1 — Single-scenario validator
```

The project should not move to M2 until M1 has a working CLI, tests, example data, and documentation.
