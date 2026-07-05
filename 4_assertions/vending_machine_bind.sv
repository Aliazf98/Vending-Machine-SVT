// ============================================================================
// Part 2 – Assertion Bind File
// ============================================================================
// Binds the SVA checker into every instance of vending_machine.
// Passes both port-level and internal signals for temporal assertions.
// ============================================================================

bind vending_machine vending_machine_assertions ASSERT_BIND (
    // DUT ports
    .clk          (clk),
    .rst          (rst),
    .coin_in      (coin_in),
    .button_in    (button_in),
    .change_out   (change_out),
    .beverage_out (beverage_out),
    // DUT internals
    .state        (state),
    .credit       (credit),
    .dispense_cnt (dispense_cnt),
    .change_cnt   (change_cnt),
    .sel_beverage (sel_beverage)
);
