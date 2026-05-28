//THIS IS MY 3 STAGE PIPELINED PARAMETERIZED PROCESSING ELEMENT
////the output is supposed to arrive 2 cycles later...altho latency increases
//by 2 cycles, throughput remains the same

module pe_3_stage #(parameter int DATA_WIDTH = 16, int FRAC_BITS = 15, int FILTER_TAPS = 8,
localparam int ACC_WIDTH = 2*DATA_WIDTH - FRAC_BITS + $clog2(FILTER_TAPS))
//this might not work with every compiler and simulator...it does work with
//iverilog tho...to be completely safe i must do it as parameter itself
(
  input logic clk,rst,
  input logic load_weight,
  input logic signed [DATA_WIDTH-1:0]x_in,
  input logic signed [DATA_WIDTH-1:0]h_in,
  input logic signed [ACC_WIDTH-1:0]acc_in,
  output logic signed [DATA_WIDTH-1:0]x_out,
  output logic signed [DATA_WIDTH-1:0]h_out,
  output logic signed [ACC_WIDTH-1:0]acc_out
);
//this formula is for using ACC_WIDTH instead of asking the user to give it as
//a parameter...this works like max width of the multiplication will be Q<smtg>
//* Q<smtg> which is basically 2*DATA_WIDTH...then to scale it down we do the
//usual right shift (along with rounding but that doesnt affect it) and the
//rest are the so called "guard bits" which basically give a headroom for
//accumulation to happen without overflow...with each tap increase, acc
//increases by 1 bit so adding $clog2(N)

logic signed [2*DATA_WIDTH-1:0]mult_mult_stage;
logic signed [DATA_WIDTH-1:0]mult_shift_stage; //here ive done this so as to preserve
//the actual width of the shifted mult...this will be properly 16 bits
//which will get 0 extended when adding with acc_shift_stage and the sign
//bits of both will be preseved and -ve accumulation will not be harmed
logic signed [DATA_WIDTH-1:0]x_mult_stage,x_shift_stage;
logic signed [DATA_WIDTH-1:0]h_mult_stage,h_shift_stage;
logic signed [ACC_WIDTH-1:0]acc_mult_stage,acc_shift_stage;
logic signed [DATA_WIDTH-1:0]weight_reg; //ill be using this to latch the h_in
//for multiply stage

always_ff @(posedge clk or negedge rst) begin
  if(!rst) begin
    acc_out <= 0;
    x_out <= 0;
    x_mult_stage <= 0;
    x_shift_stage <= 0;
    h_out <= 0;
    h_mult_stage <= 0;
    h_shift_stage <= 0;
    weight_reg <= 0;
    acc_mult_stage <= 0;
    acc_shift_stage <= 0;
    mult_mult_stage <= 0;
    mult_shift_stage <= 0;
  end
  else begin
    //multiply stage
    if(load_weight)
      weight_reg <= h_in;
    mult_mult_stage <= x_in * weight_reg;
    x_mult_stage <= x_in;
    h_mult_stage <= h_in;
    acc_mult_stage <= acc_in;

    //shift stage
    mult_shift_stage <= (mult_mult_stage + ((2*DATA_WIDTH)'(1)<<(FRAC_BITS-1))) >>> FRAC_BITS;
    //this casting is done to make sure there r no overflow problems in higher
    //formats...for smaller its fine just adding 1<<FRAC_BITS-1
    x_shift_stage <= x_mult_stage;
    h_shift_stage <= h_mult_stage;
    acc_shift_stage <= acc_mult_stage;

    //accumulate stage
    acc_out <= acc_shift_stage + mult_shift_stage;
    x_out <= x_shift_stage;
    h_out <= h_shift_stage;
  end
end
endmodule
