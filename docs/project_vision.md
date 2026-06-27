# Project Vision

## Why this is the best project?

It connects everything in my career:
- Solar grid connection → direct fit
- Reinforcement data validation → strong professional value
- Performance/revenue analysis → possible module later
- Python experience → useful for reference scripts, test generation and comparison
- C learning → it requires structs, headers, parsing, memory managment, arrays, dynamic lists, file I/O, CLI arguments, testing, documentation and eventually function pointers / plugin-like validation rules

I has a real Brazilian regulatory angle. ANEEL's PRODIST page says `REN 956/2021` stabilishes technical distribution procedures, while `REN 1000/2021` stabilishes distribution-service rules and is complemented by PRODIST. Module 8 defines voltage quality such as adequate, precarious, and critical ranges, and DRP/DRC indicators. 

## Product Vision

The tool should answer:

> Given the utility’s study outputs, is the proposed reinforcement technically justified, or are there alternative scenarios that satisfy voltage/loading constraints with less intervention?

Examples inputs:

```
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

scenario_with_utility_reinforcement/
  buses.csv
  lines.csv
  transformers.csv
  summary.csv

config.ini
```

Exemples output:

```
Scenario: with_pv_no_reinforcement

Voltage violations:
- Bus MT_032: 1.064 pu
- Bus MT_041: 1.071 pu

Thermal violations:
- Line L_102: 118.4 %
- Transformer TR_01: 103.2 %

Scenario: with_utility_reinforcement

Voltage violations:
- None

Thermal violations:
- None

Possible challenge:
- Utility reinforcement solves the issue, but limiting element L_102 alone caused the thermal violation.
- Alternative scenario should test reconductoring only L_102 before replacing transformer TR_01.
```

## Project Roadmap

The project will be developed in progressive milestones. Each milestone must produce a usable result while also introducing new C programming concepts and power-systems concepts.

### Phase 1 — C CLI validator

Build a command-line tool that reads one grid-study scenario from CSV files, validates voltage and loading constraints, and generates a Markdown report.

This phase does not include power-flow calculation yet.

### Phase 2 — Scenario comparison

Compare base, requested-generation, and utility-reinforcement scenarios to identify violations, limiting elements, and whether the proposed reinforcement seems technically justified.

### Phase 3 — Educational power-flow engine

Implement a simplified balanced radial power-flow engine to rebuild the mathematical foundation behind voltage drop, current flow, losses, and constraint validation.

The first solver should use a backward/forward sweep approach before considering more complex methods.

### Phase 4 — DSS C-API / OpenDSS integration

Integrate with DSS C-API or OpenDSS so the tool can eventually run scenarios directly, export results, validate constraints, and generate technical reports automatically.

This phase is advanced and should not be the starting point.

For detailed milestones, deliverables, learning goals, and completion criteria, see `docs/roadmap.md`.


## Suggested repo structure

```
dss-reinforcement-validator/
  AGENTS.md
  README.md
  docs/
    project-vision.md
    engineering-notes.md
    power-flow-learning.md
    brazilian-grid-connection-context.md
  include/
    gridval/
      scenario.h
      bus.h
      line.h
      transformer.h
      validation.h
      report.h
  src/
    main.c
    scenario.c
    bus.c
    line.c
    transformer.c
    validation.c
    report.c
  tests/
    test_validation.c
    test_csv_parser.c
    fixtures/
      simple_feeder/
  examples/
    scenario_base/
    scenario_with_pv/
    scenario_with_reinforcement/
  scripts/
    python_reference/
  build/
```

`build` should be ingored by Git.