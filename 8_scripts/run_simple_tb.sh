#!/bin/bash
# ============================================================================
# Run the simple directed testbench (Part 1.2)
# Requires: Icarus Verilog (iverilog/vvp) or ModelSim/QuestaSim
# ============================================================================
set -e

PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RTL_DIR="$PROJ_ROOT/1_rtl"
TB_DIR="$PROJ_ROOT/2_simple_tb"
VCD_DIR="$PROJ_ROOT/6_vcd_traces"

echo "============================================"
echo " Part 1.2 – Simple Directed Testbench"
echo "============================================"

# --- Option A: Icarus Verilog ---
if command -v iverilog &> /dev/null; then
    echo "[INFO] Using Icarus Verilog"
    iverilog -g2012 \
        -o "$PROJ_ROOT/sim_simple_tb" \
        "$RTL_DIR/vending_machine.sv" \
        "$TB_DIR/tb_vending_machine.sv"
    cd "$VCD_DIR"
    vvp "$PROJ_ROOT/sim_simple_tb"
    echo "[INFO] VCD trace written to $VCD_DIR/vending_machine.vcd"
    rm -f "$PROJ_ROOT/sim_simple_tb"

# --- Option B: QuestaSim / ModelSim ---
elif command -v vsim &> /dev/null; then
    echo "[INFO] Using QuestaSim/ModelSim"
    cd "$VCD_DIR"
    vlog -sv "$RTL_DIR/vending_machine.sv" "$TB_DIR/tb_vending_machine.sv"
    vsim -c -do "run -all; quit" tb_vending_machine

else
    echo "[ERROR] No supported simulator found (iverilog or vsim required)."
    exit 1
fi

echo "============================================"
echo " Done."
echo "============================================"
