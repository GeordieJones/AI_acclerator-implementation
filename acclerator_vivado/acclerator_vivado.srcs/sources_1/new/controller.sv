`timescale 1ns / 1ps


module controller #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    input  logic [ADDR_WIDTH-1:0] k_dim,

    output logic [ADDR_WIDTH-1:0] read_addr_a,
    output logic [ADDR_WIDTH-1:0] read_addr_b,
    output logic                  read_en,
    output logic                  clr_acc,
    output logic                  bank_select,
    output logic                  done
);

    typedef enum logic [2:0] {
        ST_IDLE     = 3'b000,
        ST_CLEAR    = 3'b001,
        ST_COMPUTE  = 3'b010,
        ST_DRAIN    = 3'b011,
        ST_SWAP     = 3'b100
    } state_t;

    state_t state, next_state;

    logic [ADDR_WIDTH-1:0] cnt_k;
    logic [3:0]            cnt_drain;

    localparam int DRAIN_CYCLES = 6;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= ST_IDLE;
            cnt_k       <= '0;
            cnt_drain   <= '0;
            bank_select <= 1'b0;
        end 
        else begin
            state <= next_state;

            case (state)
                ST_IDLE, ST_CLEAR: begin
                    cnt_k     <= '0;
                    cnt_drain <= '0;
                end

                ST_COMPUTE: begin
                    if (cnt_k < k_dim - 1) begin
                        cnt_k <= cnt_k + 1'b1;
                    end
                end

                ST_DRAIN: begin
                    if (cnt_drain < DRAIN_CYCLES) begin
                        cnt_drain <= cnt_drain + 1'b1;
                    end
                end

                ST_SWAP: begin
                    bank_select <= ~bank_select;
                end

                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        read_en = 1'b0;
        clr_acc = 1'b0;
        done = 1'b0;
        read_addr_a = '0;
        read_addr_b = '0;

        case (state)
            ST_IDLE: begin
                if (start) begin
                    next_state = ST_CLEAR;
                end
            end

            ST_CLEAR: begin
                clr_acc = 1'b1;
                next_state = ST_COMPUTE;
            end

            ST_COMPUTE: begin
                read_en = 1'b1;
                read_addr_a = cnt_k;
                read_addr_b = cnt_k;

                if (cnt_k == k_dim - 1) begin
                    next_state = ST_DRAIN;
                end
            end

            ST_DRAIN: begin
                read_en = 1'b0;

                if (cnt_drain == DRAIN_CYCLES - 1) begin
                    next_state = ST_SWAP;
                end
            end

            ST_SWAP: begin
                done = 1'b1;
                next_state = ST_IDLE;
            end

            default: next_state = ST_IDLE;
        endcase
    end

endmodule
