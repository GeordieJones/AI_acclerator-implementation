`timescale 1ns / 1ps


module dual_port_ram #(
        parameter int DATA_WIDTH = 8,
        parameter int DEPTH = 16,
        parameter int ADDR_WIDTH = $clog2(DEPTH)
    )(
        input logic clk,
        input logic we_a,
        input logic [ADDR_WIDTH-1:0] addr_a,
        input logic [DATA_WIDTH-1:0] din_a,
        
        input logic [ADDR_WIDTH-1:0] addr_b,
        output logic [DATA_WIDTH-1:0] dout_b
    );
    
    logic [DATA_WIDTH-1:0] ram [0:DEPTH-1];
    
    always_ff @(posedge clk) begin
        if(we_a) begin
            ram[addr_a] <= din_a;
        end
    end
    
    always_ff @(posedge clk) begin
        dout_b <= ram[addr_b];
    end
    
endmodule
