`timescale 1ns/1ps
// Counts quarter-clock edges against 100 MHz. Resolution is RATE_SCALE kHz.
// enable resets the observation window, NOT the measured clock or source counter.
module serdes4_rate_meter #(parameter integer WINDOW=100000)(
 input wire measured_clk,host_clk,rst,enable,
 output reg [31:0] khz=0,output reg valid=0);
 localparam integer RATE_SCALE=400000/WINDOW;
 initial if(WINDOW<100 || 400000%WINDOW!=0)$error("Unsupported meter window");
 (* ASYNC_REG="TRUE" *) reg [2:0] reset_pipe=7;
 always @(posedge measured_clk or posedge rst)
  if(rst)reset_pipe<=7;else reset_pipe<={reset_pipe[1:0],1'b0};
 wire source_reset=reset_pipe[2];
 reg [23:0] binary_count=0,gray_count=0;
 wire [23:0] next_count=binary_count+1'b1;
 always @(posedge measured_clk or posedge source_reset)
  if(source_reset)begin binary_count<=0;gray_count<=0;end
  else begin binary_count<=next_count;gray_count<=next_count^(next_count>>1);end
 (* ASYNC_REG="TRUE" *) reg [23:0] gray_meta=0,gray_sync=0;
 reg [23:0] decoded,last_count=0;reg [31:0] timer=0;reg primed=0;
 always @*begin
  decoded[23]=gray_sync[23];for(integer b=22;b>=0;b=b-1)decoded[b]=decoded[b+1]^gray_sync[b];
 end
 always @(posedge host_clk)begin
  gray_meta<=gray_count;gray_sync<=gray_meta;valid<=0;
  if(rst || !enable)begin timer<=0;primed<=0;last_count<=decoded;khz<=0;end
  else if(timer==WINDOW-1)begin
   timer<=0;primed<=1;valid<=primed;last_count<=decoded;
   khz<=24'(decoded-last_count)*RATE_SCALE;
  end else timer<=timer+1'b1;
 end
endmodule
