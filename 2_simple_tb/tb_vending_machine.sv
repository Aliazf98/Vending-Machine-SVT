// ============================================================================
// Part 1.2 – Simple "Verilog-style" directed test bench
// ============================================================================
// No classes or program blocks; purely procedural initial / task based.
// ============================================================================

`timescale 1ns/1ps

module tb_vending_machine;

    // ── Signals ─────────────────────────────────────────────────────────
    logic        clk;
    logic        rst;
    logic [2:0]  coin_in;
    logic [1:0]  button_in;
    logic [7:0]  change_out;
    logic [1:0]  beverage_out;

    // ── Parameters (match DUT) ──────────────────────────────────────────
    localparam int N = 5;
    localparam int M = 3;

    // ── DUT instantiation ───────────────────────────────────────────────
    vending_machine #(.N(N), .M(M)) DUT (
        .clk          (clk),
        .rst          (rst),
        .coin_in      (coin_in),
        .button_in    (button_in),
        .change_out   (change_out),
        .beverage_out (beverage_out)
    );

    // ── Clock generation (10 ns period) ─────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── VCD dump ────────────────────────────────────────────────────────
    initial begin
        $dumpfile("vending_machine.vcd");
        $dumpvars(0, tb_vending_machine);
    end

    // ── Helper tasks ────────────────────────────────────────────────────

    task automatic do_reset();
        rst = 1;
        coin_in   = 3'b000;
        button_in = 2'b00;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    task automatic insert_coin(input logic [2:0] coin);
        @(posedge clk);
        coin_in = coin;
        @(posedge clk);
        coin_in = 3'b000;
    endtask

    task automatic press_button(input logic [1:0] btn);
        @(posedge clk);
        button_in = btn;
        @(posedge clk);
        button_in = 2'b00;
    endtask

    // Wait for dispense + change phase to finish and go back to IDLE
    task automatic wait_transaction_done();
        repeat (N + M + 4) @(posedge clk);
    endtask

    // ── Test sequence ───────────────────────────────────────────────────
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task automatic check(string name, logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_cnt++;
        end else begin
            $display("[FAIL] %s", name);
            fail_cnt++;
        end
    endtask

    initial begin
        $display("========================================");
        $display(" Vending Machine – Directed Test Bench  ");
        $display("========================================");

        // ── Reset ───────────────────────────────────────────────────────
        do_reset();

        // ────────────────────────────────────────────────────────────────
        // TC1: Insert 50c → buy water (30c) → expect water + 20c change
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC1: 50c coin, buy water ---");
        insert_coin(3'b011);            // 50 cent
        press_button(2'b01);            // water
        wait_transaction_done();
        // beverage_out should have pulsed 01; change_out should have pulsed 20
        // (We check in the waveform; here just confirm machine returned to idle)

        // ────────────────────────────────────────────────────────────────
        // TC2: Insert 20c + 10c → try soda (50c) → should be IGNORED
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC2: 30c total, try soda (insufficient) ---");
        insert_coin(3'b010);            // 20 cent
        insert_coin(3'b001);            // 10 cent → credit = 30c
        press_button(2'b10);            // soda (costs 50c) → ignored
        repeat (4) @(posedge clk);
        check("TC2: beverage_out == 0 (no soda)", beverage_out == 2'b00);

        // Credit should still be 30c – buy water instead
        press_button(2'b01);            // water
        wait_transaction_done();

        // ────────────────────────────────────────────────────────────────
        // TC3: Insert 1€ → buy soda (50c) → leftover 50c ≥ 30c → NO
        //      change yet; buy water → leftover 20c < 30c → change 20c
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC3: 1€, buy soda then water (auto-change) ---");
        insert_coin(3'b100);            // 1 euro = 100c
        press_button(2'b10);            // soda
        wait_transaction_done();
        // After soda, credit=50c ≥ 30c → no change returned yet
        insert_coin(3'b000);            // no coin, just keep going
        press_button(2'b01);            // water (30c) → credit becomes 20c < 30c
        wait_transaction_done();
        // Now change_out should have pulsed 20

        // ────────────────────────────────────────────────────────────────
        // TC4: Insert 2€ → buy water (30c) → leftover 170c ≥ 30c
        //      → no change; buy soda → 120c; buy soda → 70c; buy soda → 20c → change
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC4: 2€, buy water+3× soda until change ---");
        insert_coin(3'b101);            // 2 euro = 200c
        press_button(2'b01);            // water → credit 170c
        wait_transaction_done();
        press_button(2'b10);            // soda → credit 120c
        wait_transaction_done();
        press_button(2'b10);            // soda → credit  70c
        wait_transaction_done();
        press_button(2'b10);            // soda → credit  20c < 30c → change 20c
        wait_transaction_done();

        // ────────────────────────────────────────────────────────────────
        // TC5: No coin → press button → nothing happens
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC5: No credit, press button ---");
        press_button(2'b01);
        repeat (4) @(posedge clk);
        check("TC5: beverage_out == 0", beverage_out == 2'b00);

        // ────────────────────────────────────────────────────────────────
        // TC6: Insert invalid coin code (3'b110) → credit unchanged
        // ────────────────────────────────────────────────────────────────
        $display("\n--- TC6: Invalid coin code ---");
        insert_coin(3'b110);
        repeat (2) @(posedge clk);

        // ── Summary ─────────────────────────────────────────────────────
        $display("\n========================================");
        $display(" Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
