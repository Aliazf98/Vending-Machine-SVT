# Vending Machine SVT

SystemVerilog verification project for the **System Verification and Testing** course.

This repository presents a complete verification flow for a vending machine RTL design. The project includes directed testing, constrained-random verification, SystemVerilog Assertions, contingency-table based assertion analysis, VCD waveform inspection, and HARM-based assertion mining.

## Project Goal

The goal of this project is to verify the functional correctness of a vending machine finite-state machine and analyze its behavior using both manual and mined assertions.

The vending machine accepts coins, accumulates credit, dispenses beverages, and returns change when the remaining credit is lower than the minimum beverage price.

## AI Engineering Perspective

From an AI engineering perspective, this project can be seen as a small verification pipeline based on structured input generation, trace analysis, rule checking, and property mining.

The RTL design is the system under test. The testbenches generate input data, the monitor observes the system behavior, the scoreboard evaluates correctness, and assertions define formal temporal rules. The VCD trace acts as time-series execution data, while HARM mines behavioral properties from this trace.

This connects classical hardware verification with data-driven engineering concepts such as automated pattern discovery, rule extraction, behavioral validation, and comparison between expected and mined properties.

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
```

## RTL Design

The vending machine is implemented as a finite-state machine with four main states:

```text
IDLE
ACCEPT_COIN
DISPENSE
RETURN_CHANGE
```

The design supports:

- coin insertion
- credit accumulation
- beverage selection
- beverage dispensing
- automatic change return
- invalid input handling

## Directed Testbench

The directed testbench validates known scenarios, including:

- valid water purchase
- valid soda purchase
- insufficient credit
- multiple purchases using one credit balance
- invalid coin input
- button press without credit
- automatic change return

This testbench is useful for checking expected behavior in controlled conditions.

## Constrained-Random Testbench

The constrained-random environment uses a class-based SystemVerilog architecture:

```text
Generator -> Driver -> DUT -> Monitor -> Scoreboard
```

The generator creates randomized transactions with constraints and biased distributions. The driver applies the transactions to the DUT, the monitor observes outputs, and the scoreboard checks whether the observed behavior is correct.

## Assertion-Based Verification

Manual SystemVerilog Assertions are used to verify important safety and temporal properties, including:

- coin insertion increases credit
- valid selection eventually produces a beverage
- insufficient credit does not trigger dispensing
- dispense state transitions correctly
- return-change state returns to idle
- beverage and change are never active at the same time
- low remaining credit triggers change return

## Contingency Table Analysis

The assertion framework records whether each assertion was triggered meaningfully or passed vacuously.

The table tracks:

```text
ATCT: Antecedent True, Consequent True
ATCF: Antecedent True, Consequent False
VAC : Vacuous pass
```

This is important because an assertion can pass simply because its condition was never activated. The contingency table helps measure real assertion activation and fault coverage.

## Main Results

The constrained-random simulation completed successfully.

```text
Scoreboard errors: 0
Beverages dispensed: 46
Change events: 10
Assertions triggered non-vacuously: 5 / 7
Fault coverage: 71%
```

These results show that the vending machine behaved correctly for the tested scenarios. The non-vacuous assertion analysis also shows which properties were meaningfully exercised and which properties would need stronger stimulus generation.

## HARM Assertion Mining

HARM was used to mine temporal assertions from the generated VCD trace.

```text
Trace length: 144
Total mined assertions: 163
Mining time: 0.179 seconds
```

The mined assertions captured important behavioral patterns related to:

- credit update behavior
- reset behavior
- FSM state behavior
- output mutual exclusion
- signal stability

The mined assertions were compared with the manually written SystemVerilog Assertions to evaluate how well trace-based mining can recover expected design properties.

## How to Run

Run the simple directed testbench:

```bash
cd 8_scripts
./run_simple_tb.sh
```

Run the constrained-random testbench with assertions:

```bash
cd 8_scripts
./run_cr_tb.sh
```

Run HARM assertion mining:

```bash
cd 8_scripts
./run_harm.sh
```

## Tools Used

- SystemVerilog
- Icarus Verilog
- ModelSim / QuestaSim
- Surfer waveform viewer
- HARM assertion mining tool
- Git and GitHub

ModelSim or QuestaSim is recommended for full SystemVerilog class and assertion support.

## Report

The full project report is available here:

```text
7_report/report.md
```

The report includes the RTL design explanation, testbench architecture, assertion design, contingency table analysis, HARM mining results, and screenshots.
