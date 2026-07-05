// ============================================================================
// Part 1.3 – Constrained-Random Test Bench – Test module
// ============================================================================
// NOTE: vending_machine_tb_pkg.sv is compiled separately by the run script.
// NOTE: Uses 'module' instead of 'program' for ModelSim PE compatibility.

module vending_machine_test (vending_machine_intf intf);

    import vending_machine_tb_pkg::*;

    vm_environment env;

    initial begin
        $display("========================================");
        $display(" Constrained-Random Test - Start        ");
        $display("========================================");
        env = new(intf, 200);   // 200 random transactions
        env.run();
        $display(" Constrained-Random Test - End          ");
        $display("========================================");
        $finish;
    end

endmodule
