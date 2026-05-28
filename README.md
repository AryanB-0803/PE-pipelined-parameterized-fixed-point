# PE-pipelined-parameterized-fixed-point

## What is it?
It is a 3 staged pipelined parameterized Processing Element (PE) with fixed point value handling used for fixed point arithmetic system application

## Parameters used
  1. DATA_WIDTH -> number of bits of data according to fixed point format used
  2. FRAC_BITS -> number of fractional bits of the fixed point format e.x if Q format is Q1.15, FRAC_BITS = 15
  3. FILTER_TAPS -> number of filter taps of the filter. This is added as the primary application of this PE is for dsp filters
  4. ACC_WIDTH -> is a localparam type which specifies the width of the accumulators. It is calculated using the formula -- ACC_WIDTH = 2*DATA_WIDTH - FRAC_BITS + $clog2(FILTER_TAPS))

## Pipeline Stages
  1. Multiply stage -> handles the multiplication of x_in and weight_reg inputs. The weight_reg input is the latched h_in when the load_weight flag is asserted
  2. Shift and Round stage -> the latched multiplication result from the previous stage is rounded and shifted to scale down the multiplied result
  3. Accumulate stage -> the shifted result is finally assigned to the outputs in this stage and accumulated to acc_out

## Simulation

### Iverilog 
iverilog -g2012 -o pe.vvp pe_3_stage.sv pe_3_stage_tb.sv
vvp pe.vvp

### Waveform visualization

#### GTKWave
gtkwave pe_3_stage.vcd

#### Surfer
surfer pe_3_stage.vcd

## Results and Waveforms
