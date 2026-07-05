// ============================================================================
// Part 1.3 – Constrained-Random Test Bench – Package
// ============================================================================
// Contains: transaction, generator, driver, monitor, scoreboard, environment
// ============================================================================

package vending_machine_tb_pkg;

// ── Transaction ─────────────────────────────────────────────────────────────
class vm_transaction;

    // Stimulus fields (set by manual_randomize)
    logic [2:0] coin_in;
    logic [1:0] button_in;
    // Set only by monitor / scoreboard
    logic [7:0] change_out;
    logic [1:0] beverage_out;

    // Manual randomization using $urandom — no license needed.
    // Replicates the same distribution as the original constraints:
    //   coin_in:   000 ~20%, 001-101 ~80%  (valid coins only)
    //   button_in: 00  ~60%, 01 ~20%, 10 ~20%
    function void manual_randomize();
        int r;
        // --- coin_in ---
        r = $urandom % 100;
        if (r < 20)
            coin_in = 3'b000;            // no coin  (20%)
        else begin
            // pick one of the 5 valid coins uniformly
            case ($urandom % 5)
                0: coin_in = 3'b001;     // 10c
                1: coin_in = 3'b010;     // 20c
                2: coin_in = 3'b011;     // 50c
                3: coin_in = 3'b100;     // 1€
                4: coin_in = 3'b101;     // 2€
            endcase
        end
        // --- button_in ---
        r = $urandom % 100;
        if (r < 60)
            button_in = 2'b00;           // no button (60%)
        else if (r < 80)
            button_in = 2'b01;           // water     (20%)
        else
            button_in = 2'b10;           // soda      (20%)
    endfunction

    function void display(string tag = "");
        $display("[%0t] %s coin_in=%0b button_in=%0b change_out=%0d beverage_out=%0b",
                 $time, tag, coin_in, button_in, change_out, beverage_out);
    endfunction

    function vm_transaction copy();
        copy = new();
        copy.coin_in      = this.coin_in;
        copy.button_in    = this.button_in;
        copy.change_out   = this.change_out;
        copy.beverage_out = this.beverage_out;
    endfunction

endclass

// ── Generator ───────────────────────────────────────────────────────────────
class vm_generator;

    vm_transaction tr;
    mailbox #(vm_transaction) gen2drv;
    event done;
    int num_transactions;

    function new(mailbox #(vm_transaction) mbx, int n = 100);
        this.gen2drv          = mbx;
        this.num_transactions = n;
    endfunction

    task run();
        for (int i = 0; i < num_transactions; i++) begin
            tr = new();
            tr.manual_randomize();
            gen2drv.put(tr.copy());
        end
        -> done;
    endtask

endclass

// ── Driver ──────────────────────────────────────────────────────────────────
class vm_driver;

    mailbox #(vm_transaction) gen2drv;
    virtual vending_machine_intf vif;

    // DUT timing parameters (must match DUT)
    int N = 5;
    int M = 3;

    function new(mailbox #(vm_transaction) mbx, virtual vending_machine_intf vif);
        this.gen2drv = mbx;
        this.vif     = vif;
    endfunction

    task reset();
        wait (vif.rst);
        vif.coin_in   = 3'b000;
        vif.button_in = 2'b00;
        wait (!vif.rst);
        @(posedge vif.clk);
    endtask

    task run();
        vm_transaction tr;
        forever begin
            gen2drv.get(tr);
            @(posedge vif.clk);

            // ── Phase 1: Insert coin (if any) ──────────────────
            if (tr.coin_in != 3'b000) begin
                vif.coin_in = tr.coin_in;
                @(posedge vif.clk);
                vif.coin_in = 3'b000;
                // Do NOT leave a dead cycle here — the DUT returns
                // to IDLE if coin_in==0 && button_in==0 in ACCEPT_COIN.
            end

            // ── Phase 2: Press button (if any) ─────────────────
            // Drive button on the VERY NEXT cycle after coin,
            // so the DUT is still in ACCEPT_COIN.
            if (tr.button_in != 2'b00) begin
                vif.button_in = tr.button_in;
                @(posedge vif.clk);
                vif.button_in = 2'b00;
                // Wait for dispense + change phases to complete
                repeat (N + M + 4) @(posedge vif.clk);
            end else begin
                // No button — just wait 1 cycle before next transaction
                @(posedge vif.clk);
            end
        end
    endtask

endclass

// ── Monitor ─────────────────────────────────────────────────────────────────
class vm_monitor;

    virtual vending_machine_intf vif;
    mailbox #(vm_transaction) mon2scb;

    function new(mailbox #(vm_transaction) mbx, virtual vending_machine_intf vif);
        this.mon2scb = mbx;
        this.vif     = vif;
    endfunction

    task run();
        vm_transaction tr;
        forever begin
            @(posedge vif.clk);
            if (vif.beverage_out != 2'b00 || vif.change_out != 8'd0) begin
                tr = new();
                tr.beverage_out = vif.beverage_out;
                tr.change_out   = vif.change_out;
                tr.coin_in      = vif.coin_in;
                tr.button_in    = vif.button_in;
                mon2scb.put(tr);
            end
        end
    endtask

endclass

// ── Scoreboard ──────────────────────────────────────────────────────────────
class vm_scoreboard;

    mailbox #(vm_transaction) mon2scb;
    int beverage_cnt = 0;
    int change_cnt   = 0;
    int error_cnt    = 0;

    function new(mailbox #(vm_transaction) mbx);
        this.mon2scb = mbx;
    endfunction

    task run();
        vm_transaction tr;
        forever begin
            mon2scb.get(tr);
            // Basic checks
            if (tr.beverage_out != 2'b00) begin
                if (tr.beverage_out != 2'b01 && tr.beverage_out != 2'b10) begin
                    $display("[SCB ERROR] Invalid beverage_out = %0b", tr.beverage_out);
                    error_cnt++;
                end else begin
                    beverage_cnt++;
                end
            end
            if (tr.change_out != 8'd0) begin
                change_cnt++;
            end
        end
    endtask

    function void report();
        $display("========================================");
        $display(" Scoreboard Report");
        $display("   Beverages dispensed : %0d", beverage_cnt);
        $display("   Change events       : %0d", change_cnt);
        $display("   Errors              : %0d", error_cnt);
        $display("========================================");
    endfunction

endclass

// ── Environment ─────────────────────────────────────────────────────────────
class vm_environment;

    vm_generator   gen;
    vm_driver      drv;
    vm_monitor     mon;
    vm_scoreboard  scb;

    mailbox #(vm_transaction) gen2drv;
    mailbox #(vm_transaction) mon2scb;

    virtual vending_machine_intf vif;

    function new(virtual vending_machine_intf vif, int num_trans = 200);
        this.vif = vif;
        gen2drv  = new();
        mon2scb  = new();
        gen = new(gen2drv, num_trans);
        drv = new(gen2drv, vif);
        mon = new(mon2scb, vif);
        scb = new(mon2scb);
    endfunction

    task run();
        // Reset phase
        drv.reset();
        // Main phase – all components run concurrently
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

        // Wait for generator to finish creating all transactions
        @(gen.done);
        $display("[ENV] Generator done. Waiting for driver to drain mailbox...");

        // Wait until the driver has consumed all transactions from the mailbox
        wait (gen2drv.num() == 0);

        // Extra time for the last transaction's dispense+change to complete
        repeat (200) @(posedge vif.clk);

        scb.report();
    endtask

endclass

endpackage
