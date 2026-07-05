// ============================================================================
// Vending Machine RTL – SystemVerilog
// ============================================================================
`timescale 1ns/1ps
// Coins  : 10c (001), 20c (010), 50c (011), 1€ (100), 2€ (101)
// Buttons: water (01) = 30c, soda (10) = 50c
// After dispensing, change is returned automatically ONLY when the remaining
// credit is less than the cheapest beverage (30c).
// Dispensing takes N cycles; returning change takes M cycles.
// During DISPENSE / RETURN_CHANGE the machine ignores coin_in & button_in.
// ============================================================================

module vending_machine #(
    parameter int N = 5,   // Beverage-delivery latency (clock cycles)
    parameter int M = 3    // Change-return latency    (clock cycles)
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [2:0]  coin_in,      // 0 = no coin
    input  logic [1:0]  button_in,    // 0 = no press
    output logic [7:0]  change_out,   // change in cents
    output logic [1:0]  beverage_out  // 01 = water, 10 = soda
);

    // ── Cost constants ──────────────────────────────────────────────────
    localparam int WATER_COST = 30;
    localparam int SODA_COST  = 50;
    localparam int MIN_COST   = WATER_COST;  // cheapest item

    // ── FSM states ──────────────────────────────────────────────────────
    typedef enum logic [2:0] {
        IDLE           = 3'd0,
        ACCEPT_COIN    = 3'd1,
        DISPENSE       = 3'd2,
        RETURN_CHANGE  = 3'd3
    } state_t;

    state_t state, next_state;

    // ── Internal registers ──────────────────────────────────────────────
    logic [7:0] credit;
    logic [7:0] dispense_cnt;  // counts N cycles
    logic [7:0] change_cnt;    // counts M cycles
    logic [1:0] sel_beverage;  // latched beverage selection
    logic [7:0] sel_cost;      // latched cost of selected beverage

    // ── Coin-value decoder (combinational) ──────────────────────────────
    function automatic logic [7:0] coin_value(input logic [2:0] c);
        case (c)
            3'b001:  return 8'd10;   // 10 cent
            3'b010:  return 8'd20;   // 20 cent
            3'b011:  return 8'd50;   // 50 cent
            3'b100:  return 8'd100;  // 1 euro
            3'b101:  return 8'd200;  // 2 euro
            default: return 8'd0;
        endcase
    endfunction

    // ── Next-state logic (combinational) ────────────────────────────────
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (coin_value(coin_in) != 0)
                    next_state = ACCEPT_COIN;
            end

            ACCEPT_COIN: begin
                // Accept another coin in this state too
                if (button_in == 2'b01 && credit >= WATER_COST)
                    next_state = DISPENSE;
                else if (button_in == 2'b10 && credit >= SODA_COST)
                    next_state = DISPENSE;
                else if (coin_value(coin_in) == 0 && button_in == 2'b00)
                    next_state = IDLE; // return to idle when nothing happens
            end

            DISPENSE: begin
                if (dispense_cnt == N - 1)
                    next_state = RETURN_CHANGE;
            end

            RETURN_CHANGE: begin
                if (change_cnt == M - 1)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ── State register ──────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ── Credit register ─────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            credit <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    credit <= credit + coin_value(coin_in);
                end

                ACCEPT_COIN: begin
                    // If transitioning to DISPENSE this cycle, subtract cost
                    if ((button_in == 2'b01 && credit >= WATER_COST) ||
                        (button_in == 2'b10 && credit >= SODA_COST)) begin
                        credit <= credit - ((button_in == 2'b01) ? WATER_COST : SODA_COST);
                    end else begin
                        credit <= credit + coin_value(coin_in);
                    end
                end

                RETURN_CHANGE: begin
                    // Clear credit on the last change-return cycle
                    if (change_cnt == M - 1)
                        credit <= 8'd0;
                end

                default: ;  // hold
            endcase
        end
    end

    // ── Latch selected beverage & cost on transition to DISPENSE ────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sel_beverage <= 2'b00;
            sel_cost     <= 8'd0;
        end else if (state == ACCEPT_COIN) begin
            if (button_in == 2'b01 && credit >= WATER_COST) begin
                sel_beverage <= 2'b01;
                sel_cost     <= WATER_COST;
            end else if (button_in == 2'b10 && credit >= SODA_COST) begin
                sel_beverage <= 2'b10;
                sel_cost     <= SODA_COST;
            end
        end
    end

    // ── Dispense counter ────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            dispense_cnt <= 8'd0;
        else if (state == DISPENSE)
            dispense_cnt <= dispense_cnt + 1;
        else
            dispense_cnt <= 8'd0;
    end

    // ── Change counter ──────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            change_cnt <= 8'd0;
        else if (state == RETURN_CHANGE)
            change_cnt <= change_cnt + 1;
        else
            change_cnt <= 8'd0;
    end

    // ── Output: beverage_out ────────────────────────────────────────────
    // Asserted for one cycle at the END of the DISPENSE phase
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            beverage_out <= 2'b00;
        else if (state == DISPENSE && dispense_cnt == N - 1)
            beverage_out <= sel_beverage;
        else
            beverage_out <= 2'b00;
    end

    // ── Output: change_out ──────────────────────────────────────────────
    // Asserted for one cycle at the END of the RETURN_CHANGE phase,
    // but ONLY if remaining credit < cheapest beverage.
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            change_out <= 8'd0;
        else if (state == RETURN_CHANGE && change_cnt == M - 1 && credit < MIN_COST)
            change_out <= credit;
        else
            change_out <= 8'd0;
    end

endmodule

