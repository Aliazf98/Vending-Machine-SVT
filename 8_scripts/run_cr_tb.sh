#!/bin/bash
# ============================================================================
# Run the constrained-random testbench with assertions (Part 1.3 + Part 2)
# Requires: QuestaSim / ModelSim (for full SV class & assertion support)
#           or Icarus Verilog (limited SV support)
# ============================================================================
set -e

PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RTL_DIR="$PROJ_ROOT/1_rtl"
CR_TB_DIR="$PROJ_ROOT/3_constrained_random_tb"
ASSERT_DIR="$PROJ_ROOT/4_assertions"
VCD_DIR="$PROJ_ROOT/6_vcd_traces"

echo "============================================"
echo " Part 1.3 + Part 2 – CR-TB with Assertions"
echo "============================================"

# --- Option A: QuestaSim / ModelSim (recommended) ---
if command -v vsim &> /dev/null; then
    echo "[INFO] Using QuestaSim/ModelSim"
    cd "$VCD_DIR"

    # Compile all source files
    # NOTE: bind file is NOT compiled — assertions are instantiated directly
    #       in tbench_top.sv for ModelSim PE compatibility.
    vlog -sv \
        "$RTL_DIR/vending_machine_intf.sv" \
        "$RTL_DIR/vending_machine.sv" \
        "$ASSERT_DIR/vending_machine_assertions.sv" \
        "$CR_TB_DIR/vending_machine_tb_pkg.sv" \
        "$CR_TB_DIR/vending_machine_test.sv" \
        "$CR_TB_DIR/tbench_top.sv"

    # Run simulation
    vsim -c -do "run -all; quit" tbench_top
    echo "[INFO] VCD trace written to $VCD_DIR/"

# --- Option B: Icarus Verilog (limited SV support) ---
elif command -v iverilog &> /dev/null; then
    echo "[INFO] Using Icarus Verilog (limited SV class support)"
    echo "[WARN] Icarus may not support all SV constructs (classes, bind, etc.)"
    echo "[WARN] Use QuestaSim/ModelSim for full compatibility."

    iverilog -g2012 \
        -o "$PROJ_ROOT/sim_cr_tb" \
        -I "$RTL_DIR" \
        -I "$ASSERT_DIR" \
        "$CR_TB_DIR/tbench_top.sv"
    cd "$VCD_DIR"
    vvp "$PROJ_ROOT/sim_cr_tb"
    rm -f "$PROJ_ROOT/sim_cr_tb"

else
    echo "[ERROR] No supported simulator found (vsim or iverilog required)."
    exit 1
fi

echo "============================================"
echo " Done. Check the contingency table output."
echo "============================================"
