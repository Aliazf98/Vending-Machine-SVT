// ============================================================================
// Part 1.3 – Constrained-Random Test Bench – Top-level module
// ============================================================================
// Instantiates clock, reset, interface, DUT, and the test program.
// ============================================================================

`timescale 1ns/1ps

// NOTE: All files are compiled separately by the run script (vlog/iverilog).
// Do NOT use `include here — it causes duplicate-definition errors when
// the simulator already has the compilation units loaded.

module tbench_top;

    // ── Clock & Reset ───────────────────────────────────────────────────
    logic clk = 0;
    logic rst;

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
    end

    // ── Interface ───────────────────────────────────────────────────────
    vending_machine_intf intf (clk, rst);

    // ── DUT ─────────────────────────────────────────────────────────────
    vending_machine #(.N(5), .M(3)) DUT (
        .clk          (clk),
        .rst          (rst),
        .coin_in      (intf.coin_in),
        .button_in    (intf.button_in),
        .change_out   (intf.change_out),
        .beverage_out (intf.beverage_out)
    );

    // ── Test module ───────────────────────────────────────────────────
    vending_machine_test test_inst (intf);

    // ── Assertions (direct instantiation instead of bind for ModelSim PE) ─
    vending_machine_assertions ASSERT_BIND (
        .clk          (clk),
        .rst          (rst),
        .coin_in      (intf.coin_in),
        .button_in    (intf.button_in),
        .change_out   (intf.change_out),
        .beverage_out (intf.beverage_out),
        .state        (DUT.state),
        .credit       (DUT.credit),
        .dispense_cnt (DUT.dispense_cnt),
        .change_cnt   (DUT.change_cnt),
        .sel_beverage (DUT.sel_beverage)
    );

    // ── VCD dump ────────────────────────────────────────────────────────
    initial begin
        $dumpfile("vending_machine_cr.vcd");
        $dumpvars(0, tbench_top);
    end

endmodule
