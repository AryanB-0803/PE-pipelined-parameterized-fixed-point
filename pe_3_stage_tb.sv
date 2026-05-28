module pe_3_stage_tb;

parameter int DATA_WIDTH = 16;
parameter int FRAC_BITS = 15;
parameter int FILTER_TAPS = 8;
localparam int ACC_WIDTH = 2*DATA_WIDTH - FRAC_BITS + $clog2(FILTER_TAPS);

logic clk, rst;
logic signed [DATA_WIDTH-1:0] x_in, h;
logic signed [ACC_WIDTH-1:0] acc_in;
logic signed [DATA_WIDTH-1:0] x_out;
logic signed [ACC_WIDTH-1:0] acc_out;

pe_3_stage #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS), .FILTER_TAPS(FILTER_TAPS)) dut (.*);

always #5 clk = ~clk;

initial begin
    $dumpfile("pe_3_stage.vcd");
    $dumpvars(0,pe_3_stage_tb);
    clk = 0; rst = 0;
    #10 rst = 1;

    // test 1: simple multiply accumulate
    x_in = 16'h4000; h = 16'h4000; acc_in = 0;
    #10;
    x_in = 16'h2000; h = 16'h2000; acc_in = 0;
    #10;
    x_in = 0; h = 0; acc_in = 0;
    #30; // wait for pipeline to flush

    // test 2: negative values
    x_in = -16'h4000; h = 16'h4000; acc_in = 0;
    #10;
    x_in = 0; h = 0; acc_in = 0;
    #30;

    // test 3: accumulation
    x_in = 16'h1000; h = 16'h1000; acc_in = 20'h00010;
    #10;
    x_in = 0; h = 0; acc_in = 0;
    #30;

    $display("simulation done");
    $finish;
end

initial begin
    $monitor("t=%0t | x_in=%0d h=%0d acc_in=%0d || x_out=%0d acc_out=%0d",
              $time, x_in, h, acc_in, x_out, acc_out);
end

endmodule
