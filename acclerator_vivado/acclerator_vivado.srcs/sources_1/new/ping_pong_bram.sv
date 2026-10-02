`timescale 1ns / 1ps


module ping_pong_bram #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic clk,
    input  logic bank_select,
    input  logic load_we_a,
    input  logic [ADDR_WIDTH-1:0] load_addr_a,
    input  logic [DATA_WIDTH-1:0] load_din_a,

    input  logic load_we_b,
    input  logic [ADDR_WIDTH-1:0] load_addr_b,
    input  logic [DATA_WIDTH-1:0] load_din_b,

    input  logic [ADDR_WIDTH-1:0] read_addr_a,
    output logic [DATA_WIDTH-1:0] sys_dout_a,

    input  logic [ADDR_WIDTH-1:0] read_addr_b,
    output logic [DATA_WIDTH-1:0] sys_dout_b
);
    
    logic we_a0, we_a1;
    logic [ADDR_WIDTH-1:0] addr_a0_w, addr_a1_w;
    logic [ADDR_WIDTH-1:0] addr_a0_r, addr_a1_r;
    logic [DATA_WIDTH-1:0] dout_a0, dout_a1;

    logic we_b0, we_b1;
    logic [ADDR_WIDTH-1:0] addr_b0_w, addr_b1_w;
    logic [ADDR_WIDTH-1:0] addr_b0_r, addr_b1_r;
    logic [DATA_WIDTH-1:0] dout_b0, dout_b1;
    
    always_comb begin
        if (bank_select == 1'b0) begin
           
            we_a0 = 1'b0;
            addr_a0_w = '0;
            addr_a0_r = read_addr_a;
            we_a1 = load_we_a;
            addr_a1_w = load_addr_a;
            addr_a1_r = '0;

            sys_dout_a  = dout_a0;

            we_b0 = 1'b0;
            addr_b0_w = '0;
            addr_b0_r = read_addr_b;

            we_b1 = load_we_b;
            addr_b1_w = load_addr_b;
            addr_b1_r = '0;

            sys_dout_b  = dout_b0;

        end else begin

            we_a0 = load_we_a;
            addr_a0_w = load_addr_a;
            addr_a0_r = '0;
            
            we_a1 = 1'b0;
            addr_a1_w = '0;
            addr_a1_r = read_addr_a;

            sys_dout_a = dout_a1;
            
            we_b0 = load_we_b;
            addr_b0_w = load_addr_b;
            addr_b0_r = '0;

            we_b1 = 1'b0;
            addr_b1_w = '0;
            addr_b1_r = read_addr_b;

            sys_dout_b  = dout_b1;
        end
    end
    
    dual_port_ram #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) ram_a_bank0 (
        .clk(clk), .we_a(we_a0), .addr_a(addr_a0_w), .din_a(load_din_a),
        .addr_b(addr_a0_r), .dout_b(dout_a0)
    );

    dual_port_ram #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) ram_a_bank1 (
        .clk(clk), .we_a(we_a1), .addr_a(addr_a1_w), .din_a(load_din_a),
        .addr_b(addr_a1_r), .dout_b(dout_a1)
    );

    // --- Matrix B Banks ---
    dual_port_ram #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) ram_b_bank0 (
        .clk(clk), .we_a(we_b0), .addr_a(addr_b0_w), .din_a(load_din_b),
        .addr_b(addr_b0_r), .dout_b(dout_b0)
    );

    dual_port_ram #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) ram_b_bank1 (
        .clk(clk), .we_a(we_b1), .addr_a(addr_b1_w), .din_a(load_din_b),
        .addr_b(addr_b1_r), .dout_b(dout_b1)
    );
    
    
endmodule
