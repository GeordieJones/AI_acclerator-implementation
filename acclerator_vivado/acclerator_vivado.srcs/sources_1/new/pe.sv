`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 02:00:46 PM
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pe(
        input logic clk,
        input logic rst,
        input logic clr_acc,
        input logic signed [7:0] a_in,
        input logic signed [7:0] b_in,
        output logic signed [7:0] a_out,
        output logic signed [7:0] b_out,
        output logic signed [31:0] c_out
    );
    
    
    always_ff @(posedge clk) begin
        if(rst) begin
            a_out <= '0;
            b_out <= '0;
            c_out <= '0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            
            if(clr_acc) begin
                c_out <=  a_in * b_in;
            end else begin
                c_out <= c_out + (a_in * b_in);
            end
        end
        
    end
        
endmodule
