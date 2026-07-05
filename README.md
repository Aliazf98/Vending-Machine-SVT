# Vending Machine SVT

SystemVerilog verification project for the **System Verification and Testing** course.

This repository presents a complete verification flow for a vending machine RTL design. The project combines directed testing, constrained-random verification, SystemVerilog Assertions, contingency-table based assertion analysis, VCD waveform inspection, and HARM-based assertion mining.

## Project Goal

The goal of this project is to verify the functional correctness of a vending machine finite-state machine and to analyze its behavior using both manual and mined assertions.

The vending machine accepts coins, accumulates credit, dispenses beverages, and returns change when the remaining credit is lower than the minimum beverage price.

## Verification Engineering Approach

This project follows a structured verification workflow:

1. RTL design of the vending machine FSM
2. Directed testbench for deterministic scenarios
3. Constrained-random testbench for wider input-space exploration
4. Scoreboard-based output checking
5. Manual SystemVerilog Assertions for safety and temporal properties
6. Non-vacuous assertion analysis using contingency tables
7. VCD trace generation and waveform inspection
8. HARM assertion mining from simulation traces
9. Comparison between manual assertions and mined properties

## AI Engineer Perspective

From an AI engineering perspective, this project is organized as a small but complete verification pipeline.

The workflow resembles a data-driven validation system:

- The RTL design is the system under test.
- Testbenches generate structured and randomized input data.
- The monitor observes system behavior.
- The scoreboard evaluates correctness.
- Assertions act as formal rules over time-series signals.
- VCD traces provide temporal execution data.
- HARM mines behavioral properties from traces.
- Manual and mined assertions are compared to identify meaningful invariants.

This approach connects classical hardware verification with ideas commonly used in AI and data-driven engineering, such as automated pattern discovery, trace-based learning, rule extraction, and validation against expected behavior.

## Repository Structure

```text
.
├── 1_rtl/
│   ├── vending_machine.sv
│   └── vending_machine_intf.sv
├── 2_simple_tb/
│   └── tb_vending_machine.sv
├── 3_constrained_random_tb/
│   ├── vending_machine_tb_pkg.sv
│   ├── vending_machine_test.sv
│   └── tbench_top.sv
├── 4_assertions/
│   ├── vending_machine_assertions.sv
│   └── vending_machine_bind.sv
├── 5_harm/
│   ├── vending_machine_harm.xml
│   ├── mined_assertions_dump.txt
│   └── harm_log.txt
├── 6_vcd_traces/
│   └── vending_machine.vcd
├── 7_report/
│   ├── report.md
│   ├── Con-table.jpg
│   ├── Surfer-SC.png
│   ├── HARM01.png
│   ├── HARM02.png
│   ├── HARM03.png
│   └── HARM04.png
└── 8_scripts/
    ├── run_simple_tb.sh
    ├── run_cr_tb.sh
    └── run_harm.sh
