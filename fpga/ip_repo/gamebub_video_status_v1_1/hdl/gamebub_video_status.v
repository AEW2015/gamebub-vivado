`timescale 1ns/1ps
// Registered Gray frame counter and independent status flags. Pixel clock
// <=60MHz, host clock <=200MHz; no atomic relationship between status flags.
module gamebub_video_status(
 input wire pixel_clk,pixel_resetn,host_clk,host_resetn,
 input wire vblank,stream_locked,underflow,framing_error,
 output wire [27:0] status
);
 reg vs_d=0;
 reg [23:0] frame=0,gray=0;
 (* ASYNC_REG="TRUE" *) reg [23:0] gray_meta=0,gray_sync=0;
 (* ASYNC_REG="TRUE" *) reg [3:0] flag_meta=0,flag_sync=0;
 reg [23:0] binary;
 always @(posedge pixel_clk) begin
  if(!pixel_resetn) begin vs_d<=0;frame<=0;gray<=0;end
  else begin
   vs_d<=vblank;
   if(vblank && !vs_d) begin
    frame<=frame+1'b1;gray<=((frame+1'b1)>>1)^(frame+1'b1);
   end
  end
 end
 always @(posedge host_clk) begin
  if(!host_resetn) begin gray_meta<=0;gray_sync<=0;flag_meta<=0;flag_sync<=0;end
  else begin
   gray_meta<=gray;gray_sync<=gray_meta;
   flag_meta<={vblank,framing_error,underflow,stream_locked};flag_sync<=flag_meta;
  end
 end
 integer i;
 always @* begin
  binary[23]=gray_sync[23];
  for(i=22;i>=0;i=i-1) binary[i]=binary[i+1]^gray_sync[i];
 end
 assign status={binary,flag_sync};
endmodule
