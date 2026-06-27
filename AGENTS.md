# AGENTS.md — dss-reinforcement-validator

## Project identity

This repository is a professional C portfolio project for an Electrical Engineer working with Brazilian solar power plant grid connection studies.

The project is a C17 command-line tool that validates distribution-grid study scenarios related to solar plant connection, grid reinforcement, voltage violations, thermal loading, and technical evidence used in Brazilian utility Orçamento de Conexão discussions.

The project must help the user learn C deeply while also producing a useful engineering tool.

## Primary goals

1. Build a serious C portfolio project.
2. Learn C through practical implementation.
3. Rebuild knowledge of distribution power-flow analysis.
4. Create a tool that helps analyze and challenge utility reinforcement studies.
5. Produce excellent documentation and tests.
6. Use Superpowers skills in Codex for planning, TDD, debugging, review, and disciplined implementation.

## Non-goals

The project must not start by rewriting OpenDSS.

The project must not start by implementing a full Newton-Raphson unbalanced distribution power-flow solver.

The first useful product is a validator and reporter for study outputs, not a simulator.

DSS C-API/OpenDSS integration is a later phase.

## Technical scope

The first version should read exported scenario data, validate constraints, and generate Markdown reports.

Initial supported scenario data:

* buses
* lines
* transformers
* voltage magnitudes
* element loading percentages
* summary metadata

Initial validations:

* bus voltage below minimum limit
* bus voltage above maximum limit
* line loading above limit
* transformer loading above limit
* comparison between base, requested generation, and reinforcement scenarios

The tool should eventually support:

* scenario comparison
* limiting-element detection
* alternative reinforcement analysis
* simplified balanced radial power flow
* DSS C-API/OpenDSS integration

## C learning policy

The user is an advanced Python developer but a beginner/intermediate C programmer.

The agent must teach C explicitly.

When suggesting C code, the agent must explain:

* why a struct is used
* why an enum is used
* why memory is stack-allocated or heap-allocated
* who owns each pointer
* when a pointer may be NULL
* whether a function mutates its arguments
* why a header declaration belongs in include/
* why an implementation belongs in src/
* how the code should be tested

The agent should introduce C concepts gradually:

1. structs and enums
2. header/source separation
3. const correctness
4. file I/O
5. manual parsing
6. error handling
7. dynamic arrays
8. malloc/free ownership
9. function pointers for validation rules
10. modular design
11. integration with external C libraries

## Coding permission policy

The agent may write C code in chat, in explanations, or as proposed patches.

The agent must not silently edit production C files without explicit user instruction.

Before making repository changes, the agent must explain the planned change and why it is appropriate.

When the user asks for implementation help, prefer this order:

1. Explain the design.
2. Ask the user to predict the needed structs/functions.
3. Provide a small isolated example if useful.
4. Review the user’s implementation.
5. Only provide production-ready C code when the user explicitly asks for it.

The agent may create tests, documentation, examples, and temporary learning snippets more freely, but should still explain the purpose.

## Power-flow learning policy

The agent must teach power-flow concepts step by step.

Before implementing any solver, the agent must help the user understand:

* per-unit system
* bus types
* loads as P/Q
* generators as injections
* line impedance
* voltage drop
* current calculation
* apparent power flow
* thermal loading
* voltage constraints
* convergence tolerance
* radial feeder assumptions
* difference between transmission load flow and distribution feeder analysis

The first solver, if implemented, should be a simplified balanced radial feeder solver.

The agent should compare the project’s simplified calculations against OpenDSS/DSS C-API results when possible.

## Engineering assumptions

The tool focuses on medium-voltage distribution-grid connection studies for solar power plants in Brazil.

Typical scenarios:

* base case
* requested solar generation connection without reinforcement
* utility-proposed reinforcement
* alternative reinforcement scenario

Typical constraints:

* minimum voltage
* maximum voltage
* line loading
* transformer loading
* reverse power flow
* losses
* scenario comparison

Voltage and loading limits must be configurable. Hard-coded regulatory limits should be avoided unless clearly documented.

## Documentation requirements

Every milestone must include documentation.

Required docs:

* README.md
* docs/project-vision.md
* docs/engineering-notes.md
* docs/power-flow-learning.md
* docs/scenario-format.md
* docs/validation-rules.md

The README must explain:

* what problem the tool solves
* how to build it
* how to run tests
* how to run an example
* what engineering assumptions are currently supported
* what is not supported yet

## Testing requirements

Every module must have tests.

Minimum test areas:

* CSV parsing
* voltage validation
* loading validation
* scenario comparison
* report generation
* error handling for missing or malformed files

Tests should use small deterministic fixtures.

The agent should encourage test-first development when practical.

## Superpowers usage

Use Superpowers skills for:

* brainstorming project architecture
* writing implementation plans
* TDD workflow
* debugging failing tests
* reviewing code before commits
* documenting completed milestones

When using Superpowers, the agent should keep the user involved and explain decisions instead of hiding the learning process.

## Development style

Prefer simple, readable C over clever C.

Prefer explicit data structures.

Prefer small functions.

Prefer clear ownership rules.

Prefer deterministic tests.

Prefer boring, maintainable code.

Avoid premature optimization.

Avoid adding external dependencies until the internal design is clear.

## First milestone

Build a C CLI that reads one scenario from CSV files and produces a Markdown validation report.

The first milestone is complete when:

1. The project builds from the command line.
2. The user can run a sample scenario.
3. The tool detects voltage violations.
4. The tool detects loading violations.
5. The tool writes a Markdown report.
6. Tests cover the validation logic.
7. README explains how to build, test, and run the example.

## Roadmap usage

The agent must follow `docs/roadmap.md`.

Before starting any implementation, the agent must identify the current milestone, explain which learning goals are involved, and guide the user through the smallest next step.

The agent must not jump to later milestones unless the user explicitly asks.
