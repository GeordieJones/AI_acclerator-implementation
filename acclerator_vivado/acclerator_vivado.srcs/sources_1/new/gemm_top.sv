`timescale 1ns / 1ps


module gemm_top #(
            parameter int ARRAY_SIZE = 4,
            parameter int DATA_WIDTH = 8,
            parameter int ACC_WIDTH = 32,
            parameter int DEPTH = 16,
            parameter int ADDR_WIDTH = $clog2(DEPTH)
        )(
            input logic clk,
            input logic rst,
            input logic start,
            input logic load_we_a,
            input logic load_we_b,
            input logic [ADDR_WIDTH-1 : 0] k_dim,
            input logic [ADDR_WIDTH-1 : 0] load_addr_a,
            input logic [(ARRAY_SIZE*DATA_WIDTH)-1 : 0] load_din_a,
            input logic [ADDR_WIDTH-1 : 0] load_addr_b,
            input logic [(ARRAY_SIZE*DATA_WIDTH)-1 : 0] load_din_b,
                               
            output logic done,
            output logic [ACC_WIDTH-1 : 0] matrix_c [0:ARRAY_SIZE-1][0 : ARRAY_SIZE -1]
        );
        
        logic read_en, clr_acc, bank_select;
        logic [ADDR_WIDTH-1 : 0] read_addr_a, read_addr_b;        
        logic [(ARRAY_SIZE*DATA_WIDTH)-1 : 0] raw_bram_a, raw_bram_b;
        
        logic [DATA_WIDTH-1 : 0] raw_a [0: ARRAY_SIZE-1];
        logic [DATA_WIDTH-1 : 0] raw_b [0: ARRAY_SIZE-1];
        logic [DATA_WIDTH-1 : 0] skew_a [0: ARRAY_SIZE-1];
        logic [DATA_WIDTH-1 : 0] skew_b [0: ARRAY_SIZE-1];
        
        logic [DATA_WIDTH-1 : 0] delay_a_1 [0:0];
        logic [DATA_WIDTH-1 : 0] delay_a_2 [0:1];
        logic [DATA_WIDTH-1 : 0] delay_a_3 [0:2];
        
        logic [DATA_WIDTH-1 : 0] delay_b_1 [0:0];
        logic [DATA_WIDTH-1 : 0] delay_b_2 [0:1];
        logic [DATA_WIDTH-1 : 0] delay_b_3 [0:2];
        
        controller #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(DEPTH)
        ) u_controller (
            .clk(clk),
            .rst(rst),
            .start(start),
            .k_dim(k_dim),
            .read_addr_a(read_addr_a),
            .read_addr_b(read_addr_b),
            .read_en(read_en),
            .clr_acc(clr_acc),
            .bank_select(bank_select),
            .done(done)
        );
        
        ping_pong_bram #(
            .DATA_WIDTH(ARRAY_SIZE * DATA_WIDTH),
            .DEPTH(DEPTH)
        ) u_ping_pong_bram (
            .clk(clk),
            .bank_select(bank_select),
            .load_we_a(load_we_a),
            .load_addr_a(load_addr_a),
            .load_din_a(load_din_a),
            .load_we_b(load_we_b),
            .load_addr_b(load_addr_b),
            .load_din_b(load_din_b),
            
            .read_addr_a(read_addr_a),
            .sys_dout_a(raw_bram_a),
            .read_addr_b(read_addr_b),
            .sys_dout_b(raw_bram_b)
        );
        
        systolic_array #(
            .ARRAY_SIZE(ARRAY_SIZE),
            .DATA_WIDTH(DATA_WIDTH),
            .ACC_WIDTH(ACC_WIDTH)
        ) u_systolic_array (
            .clk(clk),
            .rst(rst),
            .clr_acc(clr_acc),
            .a_in(skew_a),
            .b_in(skew_b),
            .c_out(matrix_c)
        );
        
        genvar i;
        generate
            for(i = 0; i < ARRAY_SIZE; i++) begin: g_unpack
                assign raw_a[i] = raw_bram_a[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
                assign raw_b[i] = raw_bram_b[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
                
            end
        endgenerate
        
        
        always_ff @(posedge clk or posedge rst) begin
            if(rst) begin
                for(int k = 0; k < 1; k++) begin delay_a_1[k] <= '0; delay_b_1[k] <= '0; end
                for(int k = 0; k < 2; k++) begin delay_a_2[k] <= '0; delay_b_2[k] <= '0; end
                for(int k = 0; k < 3; k++) begin delay_a_3[k] <= '0; delay_b_3[k] <= '0; end
            end
            else begin 
                delay_a_1[0] <= raw_a[1];
                delay_a_2[0] <= raw_a[2];
                delay_a_3[0] <= raw_a[3];
                
                delay_a_2[1] <= delay_a_2[0];
                delay_a_3[1] <= delay_a_3[0];
                delay_a_3[2] <= delay_a_3[1];
                
                delay_b_1[0] <= raw_b[1];
                delay_b_2[0] <= raw_b[2];
                delay_b_3[0] <= raw_b[3];
                
                delay_b_2[1] <= delay_b_2[0];
                delay_b_3[1] <= delay_b_3[0];
                delay_b_3[2] <= delay_b_3[1];
                
            end
            
        end
        
        assign skew_a[0] = raw_a[0];
        assign skew_a[1] = delay_a_1[0];
        assign skew_a[2] = delay_a_1[1];
        assign skew_a[3] = delay_a_1[2];
        
        assign skew_b[0] = raw_b[0];
        assign skew_b[1] = delay_b_1[0];
        assign skew_b[2] = delay_b_1[1];
        assign skew_b[3] = delay_b_1[2];
    
    

endmodule
