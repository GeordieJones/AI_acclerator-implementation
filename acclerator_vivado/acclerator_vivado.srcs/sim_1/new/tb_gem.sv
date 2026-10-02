`timescale 1ns / 1ps

module tb_gemm;

    parameter int ARRAY_SIZE = 4;
    parameter int DATA_WIDTH = 8;
    parameter int ACC_WIDTH  = 32;
    parameter int DEPTH      = 16;
    parameter int ADDR_WIDTH = $clog2(DEPTH);
    parameter int CLK_PERIOD = 10; // 100 MHz clock

    localparam int K_TEST = 4;


    logic                                clk;
    logic                                rst;
    logic                                start;
    logic [ADDR_WIDTH-1:0]               k_dim;
    logic                                done;

    logic                                load_we_a;
    logic [ADDR_WIDTH-1:0]               load_addr_a;
    logic [(ARRAY_SIZE*DATA_WIDTH)-1:0]  load_din_a;

    logic                                load_we_b;
    logic [ADDR_WIDTH-1:0]               load_addr_b;
    logic [(ARRAY_SIZE*DATA_WIDTH)-1:0]  load_din_b;

    logic [ACC_WIDTH-1:0]                matrix_c [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];


    logic [(ARRAY_SIZE*DATA_WIDTH)-1:0] mem_a_hex [0:DEPTH-1];
    logic [(ARRAY_SIZE*DATA_WIDTH)-1:0] mem_b_hex [0:DEPTH-1];
    logic [ACC_WIDTH-1:0]                mem_c_expected [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    int error_count = 0;


    gemm_top #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .k_dim(k_dim),
        .done(done),
        .load_we_a(load_we_a),
        .load_addr_a(load_addr_a),
        .load_din_a(load_din_a),
        .load_we_b(load_we_b),
        .load_addr_b(load_addr_b),
        .load_din_b(load_din_b),
        .matrix_c(matrix_c)
    );

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;


    initial begin
        $display("   GEMM Systolic Array Self-Checking Testbench   ");
        $display("=================================================");

        init_signals();
        load_hex_files();

        apply_reset();

        load_matrices_to_bram();

        $display("[%0t ns] Triggering GEMM computation (K=%0d)...", $time, K_TEST);
        @(posedge clk);
        start <= 1'b1;
        k_dim <= K_TEST[ADDR_WIDTH-1:0];
        @(posedge clk);
        start <= 1'b0;

        @(posedge done);
        $display("[%0t ns] Hardware signal 'done' asserted!", $time);

        check_results();

        if (error_count == 0) begin
            $display("-------------------------------------------------");
            $display("  [TEST PASSED] All Matrix C outputs match!      ");
            $display("-------------------------------------------------");
        end else begin
            $display("-------------------------------------------------");
            $display("  [TEST FAILED] Total Errors: %0d               ", error_count);
            $display("-------------------------------------------------");
        end

        $finish;
    end


    task init_signals();
        rst         = 1'b0;
        start       = 1'b0;
        k_dim       = '0;
        load_we_a   = 1'b0;
        load_addr_a = '0;
        load_din_a  = '0;
        load_we_b   = 1'b0;
        load_addr_b = '0;
        load_din_b  = '0;
    endtask

    task load_hex_files();
        $display("[%0t ns] Loading memory hex files...", $time);
        $readmemh("../../../../matrix_A.hex", mem_a_hex);
        $readmemh("../../../../matrix_B.hex", mem_b_hex);
        $readmemh("../../../../matrix_C_expected.hex", mem_c_expected);
    endtask

    task apply_reset();
        $display("[%0t ns] Applying reset...", $time);
        @(posedge clk);
        rst <= 1'b1;
        repeat (3) @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);
    endtask

    task load_matrices_to_bram();
        $display("[%0t ns] Writing Matrix A and B into Ping-Pong BRAM...", $time);
        for (int i = 0; i < K_TEST; i++) begin
            @(posedge clk);
            load_we_a   <= 1'b1;
            load_addr_a <= i[ADDR_WIDTH-1:0];
            load_din_a  <= mem_a_hex[i];

            load_we_b   <= 1'b1;
            load_addr_b <= i[ADDR_WIDTH-1:0];
            load_din_b  <= mem_b_hex[i];
        end
        @(posedge clk);
        load_we_a <= 1'b0;
        load_we_b <= 1'b0;
    endtask

    task check_results();
        $display("[%0t ns] Verifying Matrix C results...", $time);
        for (int i = 0; i < ARRAY_SIZE; i++) begin
            for (int j = 0; j < ARRAY_SIZE; j++) begin
                if ($signed(matrix_c[i][j]) !== $signed(mem_c_expected[i][j])) begin
                    $display("  ERROR at C[%0d][%0d]: HW = %0d (0x%0h), Expected = %0d (0x%0h)",
                             i, j, $signed(matrix_c[i][j]), matrix_c[i][j],
                             $signed(mem_c_expected[i][j]), mem_c_expected[i][j]);
                    error_count++;
                end else begin
                    $display("  MATCH at C[%0d][%0d]: HW = %0d", i, j, $signed(matrix_c[i][j]));
                end
            end
        end
    endtask

endmodule