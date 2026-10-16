`timescale 1ns/1ps
module speaker_engine #(parameter CLOCK_HZ=29361979)(
 input wire clk,rst_n,stop_n,start,stop,heartbeat,
 input wire [31:0] frequency,level,waveform,channels,limit_ms,
 output reg running=0,output reg [2:0] reason=0,
 output reg [31:0] remaining_ms=0,frames=0,
 output wire dac_bclk,dac_wclk,dac_din);
 localparam MS_TICKS=CLOCK_HZ/1000;
 (* ASYNC_REG="TRUE" *) reg [1:0] stop_sync=0;
 reg [31:0] ms_count=0,phase=0,step=0;
 reg [9:0] lease=0,frame_cycle=0;
 reg [6:0] gain=0,target_gain=0;
 reg [1:0] shape=0,channel=0;
 reg [31:0] serial=0;reg word_clock=0;
 wire frame_tick=frame_cycle==607,ms_tick=ms_count==MS_TICKS-1;
 assign dac_bclk=~frame_cycle[2];
 assign dac_wclk=word_clock;
 assign dac_din=serial[31];
 `include "tone_sine.vh"
 reg signed [15:0] wave;
 reg signed [23:0] product;
 reg signed [15:0] sample;
 reg signed [16:0] ramp;
 always @* begin
  ramp=$signed({2'b00,phase[29:15]});
  case(shape)
   1:wave=phase[31]?-16'sd32767:16'sd32767;
   2:case(phase[31:30])
    0:wave=ramp;1:wave=17'sd32767-ramp;
    2:wave=-ramp;default:wave=-17'sd32767+ramp;
   endcase
   default:wave=sine(phase[31:24]);
  endcase
  product=wave*$signed({1'b0,gain});
  sample=running?(product/100):16'sd0;
 end
 always @(posedge clk)begin
  if(!rst_n)begin
   stop_sync<=0;running<=0;reason<=0;remaining_ms<=0;frames<=0;
   ms_count<=0;phase<=0;step<=0;lease<=0;frame_cycle<=0;
   gain<=0;target_gain<=0;shape<=0;channel<=0;serial<=0;word_clock<=0;
  end else begin
   stop_sync<={stop_sync[0],stop_n};
   ms_count<=ms_tick?0:ms_count+1;
   frame_cycle<=frame_tick?0:frame_cycle+1;
   // DSP: data changes on BCLK rising edges and is sampled falling.
   // 608 MCLK/frame, 8 MCLK/BCLK, left then right, zero padding.
   if(frame_cycle[2:0]==7)begin serial<=serial<<1;word_clock<=0;end
   if(frame_tick)begin
    serial<={(channel==2?16'd0:sample),(channel==1?16'd0:sample)};
    word_clock<=1;frames<=frames+1;phase<=phase+step;
    if(!running)gain<=0;else if(gain<target_gain)gain<=gain+1;
   end
   if(running)begin
    if(heartbeat)lease<=500;
    if(ms_tick)begin
     if(!heartbeat && lease!=0)lease<=lease-1;
     if(remaining_ms!=0)remaining_ms<=remaining_ms-1;
     if(remaining_ms<=1)begin running<=0;reason<=4;end
     if(lease<=1 && !heartbeat)begin running<=0;reason<=2;end
    end
   end
   if(start && !running)begin
    running<=1;reason<=0;remaining_ms<=limit_ms;phase<=0;gain<=0;
    // Rounded DDS step/Hz for 50 MHz * 56.375 / 3 / 32 / 608 Fs.
    // Rounding contributes under 1.3 ppm frequency error.
    step<=frequency*32'd88936;target_gain<=level[6:0];
    shape<=waveform[1:0];channel<=channels[1:0];lease<=500;ms_count<=0;
   end
   if(stop || !stop_sync[1])begin running<=0;gain<=0;reason<=!stop_sync[1]?3:0;end
  end
 end
endmodule
