module pe_3_stage_tb;

parameter int DATA_WIDTH = 16;
parameter int FRAC_BITS = 15;
parameter int FILTER_TAPS = 8;
localparam int ACC_WIDTH = 2*DATA_WIDTH - FRAC_BITS + $clog2(FILTER_TAPS);

logic clk, rst;
logic load_weight;
logic signed [DATA_WIDTH-1:0] x_in, h;
logic signed [ACC_WIDTH-1:0] acc_in;
logic signed [DATA_WIDTH-1:0] x_out;
logic signed [ACC_WIDTH-1:0] acc_out;

pe_3_stage #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS), .FILTER_TAPS(FILTER_TAPS)) dut (.clk(clk),
    .rst(rst),
    .load_weight(load_weight),
    .x_in(x_in),
    .h_in(h),
    .acc_in(acc_in),
    .x_out(x_out),
    .h_out(),          // leave unconnected if not monitored
    .acc_out(acc_out));

always #5 clk = ~clk;

// load weight then immediately drive x_in on the next cycle
task automatic load_and_run(
    input logic signed [DATA_WIDTH-1:0] weight,
    input logic signed [DATA_WIDTH-1:0] x,
    input logic signed [ACC_WIDTH-1:0]  acc
);
    // load weight cycle
    load_weight = 1;
    h = weight; x_in = 0; acc_in = 0;
    @(posedge clk); #1;
    // data cycle
    load_weight = 0;
    x_in = x; acc_in = acc;
    @(posedge clk); #1;
    // flush
    x_in = 0; h = 0; acc_in = 0;
endtask

initial begin
    $dumpfile("pe_3_stage.vcd");
    $dumpvars(0,pe_3_stage_tb);
    clk = 0; rst = 0; load_weight = 0;
    x_in = 0; h = 0; acc_in = 0;
    #10 rst = 1;

    // test 1: simple multiply accumulate
    // 0.5 * 0.5 = 0.25, acc_in = 0 -> expected acc_out = 0x2000
    load_and_run(16'h4000, 16'h4000, 0);
    #30;

    // test 2: smaller values
    // 0.25 * 0.25 = 0.0625, acc_in = 0 -> expected acc_out = 0x0800
    load_and_run(16'h2000, 16'h2000, 0);
    #30;

    // test 3: negative x, positive weight
    // -0.5 * 0.5 = -0.25 -> expected acc_out = -0x2000
    load_and_run(16'h4000, -16'sh4000, 0);
    #30;

    // test 4: positive accumulation
    // 0.125 * 0.125 = 0.015625, acc_in = 0x10 -> expected acc_out = 0x10 + small
    load_and_run(16'h1000, 16'h1000, 20'sh00010);
    #30;

    // test 5: negative mult result + positive acc_in
    // -0.25 * 0.5 = -0.125 -> mult_shift = -4096, acc_in = 0x50
    // expected acc_out = -4016 (0xff050)
    // bug: zero-extend mult_shift_stage -> wrong
    load_and_run(16'sh4000, -16'sh2000, 20'sh00050);
    #30;

    // test 6: negative acc_in + small positive mult
    // 0x0400 * 0x0400 -> shift -> 32, acc_in = -256
    // expected acc_out = -224 (0xfff20)
    // bug: zero-extend acc_shift_stage -> wrong
    load_and_run(16'sh0400, 16'sh0400, -20'sh00100);
    #30;

    $display("simulation done");
    $finish;
end

initial begin
    $monitor("t=%0t | load_weight=%0b x_in=%0d h=%0d acc_in=%0d || x_out=%0d acc_out=%0d",
              $time, load_weight, x_in, h, acc_in, x_out, acc_out);
end

endmodule
