// ============================================================================
// Vending Machine Interface
// ============================================================================
`timescale 1ns/1ps

interface vending_machine_intf (input logic clk, input logic rst);

    logic [2:0] coin_in;       // 001=10c, 010=20c, 011=50c, 100=1€, 101=2€
    logic [1:0] button_in;     // 01=water, 10=soda
    logic [7:0] change_out;    // change in cents
    logic [1:0] beverage_out;  // 01=water, 10=soda

    // ── Clocking block for the testbench (driver side) ──────────────────
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output coin_in;
        output button_in;
        input  change_out;
        input  beverage_out;
    endclocking

    // ── Clocking block for the monitor (passive) ────────────────────────
    clocking monitor_cb @(posedge clk);
        default input #1;
        input coin_in;
        input button_in;
        input change_out;
        input beverage_out;
    endclocking

    // ── Modports ────────────────────────────────────────────────────────
    modport DUT (
        input  clk, rst, coin_in, button_in,
        output change_out, beverage_out
    );

    modport DRIVER (
        clocking driver_cb,
        input clk, rst
    );

    modport MONITOR (
        clocking monitor_cb,
        input clk, rst
    );

endinterface
