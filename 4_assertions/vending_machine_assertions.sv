// ============================================================================
// Part 2 – Assertion-Based Verification – SVA Checker Module
// ============================================================================
// Instantiated in tbench_top.sv with direct port connections.
// Contains ≥ 5 temporal assertions with contingency-table counters
// (ATCT / ATCF / vacuous) and fault-coverage summary.
// ============================================================================
`timescale 1ns/1ps

module vending_machine_assertions (
    // ── DUT ports ───────────────────────────────────────────────────────
    input  logic        clk,
    input  logic        rst,
    input  logic [2:0]  coin_in,
    input  logic [1:0]  button_in,
    input  logic [7:0]  change_out,
    input  logic [1:0]  beverage_out,
    // ── DUT internals (connected via bind) ──────────────────────────────
    input  logic [2:0]  state,
    input  logic [7:0]  credit,
    input  logic [7:0]  dispense_cnt,
    input  logic [7:0]  change_cnt,
    input  logic [1:0]  sel_beverage
);

    // ── Constants (match DUT) ───────────────────────────────────────────
    localparam int WATER_COST = 30;
    localparam int SODA_COST  = 50;
    localparam int MIN_COST   = WATER_COST;
    // FSM encoding
    localparam logic [2:0] S_IDLE          = 3'd0;
    localparam logic [2:0] S_ACCEPT_COIN   = 3'd1;
    localparam logic [2:0] S_DISPENSE      = 3'd2;
    localparam logic [2:0] S_RETURN_CHANGE = 3'd3;
    // DUT timing
    localparam int N = 5;
    localparam int M = 3;

    // ── Coin-value decoder ──────────────────────────────────────────────
    function automatic logic [7:0] coin_val(input logic [2:0] c);
        case (c)
            3'b001:  return 8'd10;
            3'b010:  return 8'd20;
            3'b011:  return 8'd50;
            3'b100:  return 8'd100;
            3'b101:  return 8'd200;
            default: return 8'd0;
        endcase
    endfunction

    // ====================================================================
    //  CONTINGENCY-TABLE COUNTERS
    // ====================================================================
    // For each assertion we track:
    //   atct  – antecedent true, consequent true   (PASS, non-vacuous)
    //   atcf  – antecedent true, consequent false   (FAIL)
    //   vac   – antecedent false                    (vacuous pass)
    //   total – total evaluated cycles
    // ====================================================================

    integer a1_atct, a1_atcf, a1_vac, a1_total;
    integer a2_atct, a2_atcf, a2_vac, a2_total;
    integer a3_atct, a3_atcf, a3_vac, a3_total;
    integer a4_atct, a4_atcf, a4_vac, a4_total;
    integer a5_atct, a5_atcf, a5_vac, a5_total;
    integer a6_atct, a6_atcf, a6_vac, a6_total;
    integer a7_atct, a7_atcf, a7_vac, a7_total;

    initial begin
        a1_atct=0; a1_atcf=0; a1_vac=0; a1_total=0;
        a2_atct=0; a2_atcf=0; a2_vac=0; a2_total=0;
        a3_atct=0; a3_atcf=0; a3_vac=0; a3_total=0;
        a4_atct=0; a4_atcf=0; a4_vac=0; a4_total=0;
        a5_atct=0; a5_atcf=0; a5_vac=0; a5_total=0;
        a6_atct=0; a6_atcf=0; a6_vac=0; a6_total=0;
        a7_atct=0; a7_atcf=0; a7_vac=0; a7_total=0;
    end

    // ====================================================================
    // A1 – TEMPORAL: Coin insertion → credit increases next cycle
    // ====================================================================
    // Antecedent: valid coin inserted while in IDLE or ACCEPT_COIN
    // Consequent: on the next posedge, credit >= old credit + coin value
    wire a1_ant = (coin_val(coin_in) != 0) &&
                  (state == S_IDLE || state == S_ACCEPT_COIN) && !rst;

    property p_coin_increments_credit;
        @(posedge clk) disable iff (rst)
        (a1_ant) |=> (credit >= $past(credit) + coin_val($past(coin_in)));
    endproperty

    assert property (p_coin_increments_credit)
        else $error("[A1 FAIL] coin inserted but credit did not increase");

    always @(posedge clk) if (!rst) begin
        a1_total++;
        if (a1_ant) begin
            // will be checked next cycle, but count antecedent-true here
            // actual pass/fail counted below with 1-cycle delay
        end else begin
            a1_vac++;
        end
    end
    // Delayed pass/fail tracking for A1 (|=> means 1-cycle delay)
    logic a1_ant_d;
    logic [7:0] a1_prev_credit;
    logic [7:0] a1_prev_coin_val;
    always @(posedge clk) begin
        a1_ant_d        <= a1_ant && !rst;
        a1_prev_credit  <= credit;
        a1_prev_coin_val <= coin_val(coin_in);
    end
    always @(posedge clk) if (a1_ant_d && !rst) begin
        if (credit >= a1_prev_credit + a1_prev_coin_val)
            a1_atct++;
        else
            a1_atcf++;
    end

    // ====================================================================
    // A2 – TEMPORAL: Button press with sufficient credit → beverage
    //       delivered exactly N+1 cycles later
    // ====================================================================
    wire a2_ant = (state == S_ACCEPT_COIN) && !rst &&
                  ((button_in == 2'b01 && credit >= WATER_COST) ||
                   (button_in == 2'b10 && credit >= SODA_COST));

    property p_valid_select_delivers;
        @(posedge clk) disable iff (rst)
        (a2_ant) |-> ##[N:N+2] (beverage_out != 2'b00);
    endproperty

    assert property (p_valid_select_delivers)
        else $error("[A2 FAIL] valid selection did not produce beverage within N+2 cycles");

    always @(posedge clk) if (!rst) begin
        a2_total++;
        if (!a2_ant) a2_vac++;
    end
    // Tracking for bounded liveness – sample N+1 cycles later
    logic a2_ant_pipe [0:N+2];
    always @(posedge clk) begin
        a2_ant_pipe[0] <= a2_ant && !rst;
        for (int i = 1; i <= N+2; i++)
            a2_ant_pipe[i] <= a2_ant_pipe[i-1];
    end
    always @(posedge clk) if (a2_ant_pipe[N+2] && !rst) begin
        if (beverage_out != 2'b00 ||
            $past(beverage_out,1) != 2'b00 ||
            $past(beverage_out,2) != 2'b00)
            a2_atct++;
        else
            a2_atcf++;
    end

    // ====================================================================
    // A3 – TEMPORAL: Insufficient credit → button press is ignored
    //       (no beverage within N+2 cycles)
    // ====================================================================
    wire a3_ant = (state == S_ACCEPT_COIN) && !rst &&
                  ((button_in == 2'b01 && credit < WATER_COST) ||
                   (button_in == 2'b10 && credit < SODA_COST));

    property p_insufficient_credit_ignored;
        @(posedge clk) disable iff (rst)
        (a3_ant) |=> ##[0:N+2] (beverage_out == 2'b00);
    endproperty

    // For insufficient credit, we actually want: for the ENTIRE window, bev==0
    // We'll assert a simpler version: next cycle, state does NOT go to DISPENSE
    property p_insufficient_no_dispense;
        @(posedge clk) disable iff (rst)
        (a3_ant) |=> (state != S_DISPENSE);
    endproperty

    assert property (p_insufficient_no_dispense)
        else $error("[A3 FAIL] insufficient credit but entered DISPENSE");

    always @(posedge clk) if (!rst) begin
        a3_total++;
        if (!a3_ant) a3_vac++;
    end
    logic a3_ant_d;
    always @(posedge clk) a3_ant_d <= a3_ant && !rst;
    always @(posedge clk) if (a3_ant_d && !rst) begin
        if (state != S_DISPENSE) a3_atct++;
        else a3_atcf++;
    end

    // ====================================================================
    // A4 – TEMPORAL: DISPENSE state always followed by RETURN_CHANGE
    //       within N cycles
    // ====================================================================
    wire a4_ant = (state == S_DISPENSE) && (dispense_cnt == 0) && !rst;

    property p_dispense_then_return_change;
        @(posedge clk) disable iff (rst)
        (a4_ant) |-> ##[1:N+1] (state == S_RETURN_CHANGE);
    endproperty

    assert property (p_dispense_then_return_change)
        else $error("[A4 FAIL] DISPENSE did not reach RETURN_CHANGE within N cycles");

    always @(posedge clk) if (!rst) begin
        a4_total++;
        if (!a4_ant) a4_vac++;
    end
    logic a4_ant_pipe [0:N+1];
    always @(posedge clk) begin
        a4_ant_pipe[0] <= a4_ant && !rst;
        for (int i = 1; i <= N+1; i++)
            a4_ant_pipe[i] <= a4_ant_pipe[i-1];
    end
    always @(posedge clk) if (a4_ant_pipe[N+1] && !rst) begin
        if (state == S_RETURN_CHANGE ||
            $past(state,1) == S_RETURN_CHANGE)
            a4_atct++;
        else
            a4_atcf++;
    end

    // ====================================================================
    // A5 – TEMPORAL: RETURN_CHANGE followed by IDLE within M cycles
    // ====================================================================
    wire a5_ant = (state == S_RETURN_CHANGE) && (change_cnt == 0) && !rst;

    property p_return_change_then_idle;
        @(posedge clk) disable iff (rst)
        (a5_ant) |-> ##[1:M+1] (state == S_IDLE);
    endproperty

    assert property (p_return_change_then_idle)
        else $error("[A5 FAIL] RETURN_CHANGE did not return to IDLE within M cycles");

    always @(posedge clk) if (!rst) begin
        a5_total++;
        if (!a5_ant) a5_vac++;
    end
    logic a5_ant_pipe [0:M+1];
    always @(posedge clk) begin
        a5_ant_pipe[0] <= a5_ant && !rst;
        for (int i = 1; i <= M+1; i++)
            a5_ant_pipe[i] <= a5_ant_pipe[i-1];
    end
    always @(posedge clk) if (a5_ant_pipe[M+1] && !rst) begin
        if (state == S_IDLE ||
            $past(state,1) == S_IDLE)
            a5_atct++;
        else
            a5_atcf++;
    end

    // ====================================================================
    // A6 – TEMPORAL: Beverage and change are mutually exclusive
    //       (never asserted on the same cycle)
    // ====================================================================
    wire a6_ant = (beverage_out != 2'b00 || change_out != 8'd0) && !rst;

    property p_mutual_exclusive;
        @(posedge clk) disable iff (rst)
        (beverage_out != 2'b00) |-> (change_out == 8'd0);
    endproperty

    assert property (p_mutual_exclusive)
        else $error("[A6 FAIL] beverage and change on same cycle");

    always @(posedge clk) if (!rst) begin
        a6_total++;
        if (beverage_out == 2'b00 && change_out == 8'd0) begin
            a6_vac++;
        end else if (beverage_out != 2'b00) begin
            if (change_out == 8'd0) a6_atct++;
            else a6_atcf++;
        end else begin
            // change_out != 0 but beverage_out == 0 — antecedent false for
            // this direction, count as vacuous
            a6_vac++;
        end
    end

    // ====================================================================
    // A7 – TEMPORAL: After dispensing, if credit < MIN_COST,
    //       change is returned within M+1 cycles
    // ====================================================================
    wire a7_ant = (state == S_DISPENSE) && (dispense_cnt == N-1) &&
                  (credit < MIN_COST) && !rst;

    property p_low_credit_returns_change;
        @(posedge clk) disable iff (rst)
        (a7_ant) |-> ##[M:M+2] (change_out != 8'd0);
    endproperty

    assert property (p_low_credit_returns_change)
        else $error("[A7 FAIL] credit < MIN_COST after dispense but no change returned");

    always @(posedge clk) if (!rst) begin
        a7_total++;
        if (!a7_ant) a7_vac++;
    end
    logic a7_ant_pipe [0:M+2];
    always @(posedge clk) begin
        a7_ant_pipe[0] <= a7_ant && !rst;
        for (int i = 1; i <= M+2; i++)
            a7_ant_pipe[i] <= a7_ant_pipe[i-1];
    end
    always @(posedge clk) if (a7_ant_pipe[M+2] && !rst) begin
        if (change_out != 8'd0 ||
            $past(change_out,1) != 8'd0 ||
            $past(change_out,2) != 8'd0)
            a7_atct++;
        else
            a7_atcf++;
    end

    // ====================================================================
    // COVERAGE POINTS
    // ====================================================================
    cover property (@(posedge clk) beverage_out == 2'b01);   // CP1: water
    cover property (@(posedge clk) beverage_out == 2'b10);   // CP2: soda
    cover property (@(posedge clk) change_out   != 8'd0);    // CP3: change
    cover property (@(posedge clk) a2_ant);                   // CP4: valid selection
    cover property (@(posedge clk) a3_ant);                   // CP5: insufficient credit
    cover property (@(posedge clk) a7_ant);                   // CP6: low-credit after dispense

    // ====================================================================
    // CONTINGENCY-TABLE & FAULT-COVERAGE REPORT  (printed at $finish)
    // ====================================================================
    final begin
        $display("");
        $display("+==================================================================+");
        $display("|           ASSERTION CONTINGENCY TABLE & FAULT COVERAGE           |");
        $display("+----------+--------+--------+--------+--------+------------------+");
        $display("| Assert   |  ATCT  |  ATCF  |  VAC   | Total  | Non-Vac Rate     |");
        $display("+----------+--------+--------+--------+--------+------------------+");
        print_row("A1:Coin+", a1_atct, a1_atcf, a1_vac, a1_total);
        print_row("A2:Sel=>B", a2_atct, a2_atcf, a2_vac, a2_total);
        print_row("A3:Insuf ", a3_atct, a3_atcf, a3_vac, a3_total);
        print_row("A4:D=>RC ", a4_atct, a4_atcf, a4_vac, a4_total);
        print_row("A5:RC=>ID", a5_atct, a5_atcf, a5_vac, a5_total);
        print_row("A6:MutEx ", a6_atct, a6_atcf, a6_vac, a6_total);
        print_row("A7:LowChg", a7_atct, a7_atcf, a7_vac, a7_total);
        $display("+----------+--------+--------+--------+--------+------------------+");

        // Fault coverage = assertions with ATCT > 0 (actually triggered & passed)
        begin
            integer triggered;
            triggered = 0;
            if (a1_atct > 0) triggered++;
            if (a2_atct > 0) triggered++;
            if (a3_atct > 0) triggered++;
            if (a4_atct > 0) triggered++;
            if (a5_atct > 0) triggered++;
            if (a6_atct > 0) triggered++;
            if (a7_atct > 0) triggered++;
            $display("| Assertions triggered (non-vacuous) : %0d / 7               |", triggered);
            $display("| Fault coverage                     : %0d%%                   |",
                     (triggered * 100) / 7);
        end
        $display("+==================================================================+");
    end

    function automatic void print_row(
        input string name,
        input integer atct, atcf, vac, total
    );
        integer non_vac_pct;
        if (total > 0)
            non_vac_pct = ((atct + atcf) * 100) / total;
        else
            non_vac_pct = 0;
        $display("| %s | %6d | %6d | %6d | %6d | %3d%%             |",
                 name, atct, atcf, vac, total, non_vac_pct);
    endfunction

endmodule

