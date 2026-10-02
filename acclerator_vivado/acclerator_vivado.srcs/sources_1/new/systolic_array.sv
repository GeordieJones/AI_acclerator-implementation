`timescale 1ns / 1ps


module systolic_array#(
    parameter int ARRAY_SIZE = 4,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
        input logic clk,
        input logic rst,
        input logic clr_acc,
        input logic [DATA_WIDTH-1:0] a_in [0:ARRAY_SIZE-1],
        input logic [DATA_WIDTH-1:0] b_in [0:ARRAY_SIZE-1],
        output logic [ACC_WIDTH-1:0] c_out [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1]
    );
    
    logic signed [DATA_WIDTH-1:0] pe_a_out [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    logic signed [DATA_WIDTH-1:0] pe_b_out [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    genvar i, j;
    
    generate
        for(i = 0; i< ARRAY_SIZE; i++) begin : ROW
            for(j = 0; j < ARRAY_SIZE; j++) begin : COL
                pe pe_inst (
                    .clk (clk),
                    .rst(rst),
                    .clr_acc(clr_acc),
                    .a_in((j==0) ? a_in[i] : pe_a_out[i][j-1]),
                    .b_in((i==0) ? b_in[j] : pe_b_out[i-1][j]),
                    .a_out(pe_a_out[i][j]),
                    .b_out(pe_b_out[i][j]),
                    .c_out(c_out[i][j])
                ); 
            end
        end
    endgenerate
    
endmodule
