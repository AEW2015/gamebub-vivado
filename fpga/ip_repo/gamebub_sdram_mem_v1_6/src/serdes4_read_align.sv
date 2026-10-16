`timescale 1ns/1ps
// Related-clock descriptor crossing: launch on command CLKDIV falling edge,
// receive on read CLKDIV rising edge. Both clocks MUST come from the same
// 4:1 MMCM tree, with read phase in [0,360) serial degrees. Do not false-path
// this crossing. It has at least half a command period for setup.
// Capture indices are configuration, never inferred from data contents.
module serdes4_read_align(
 input wire clk_div,read_clk_div,rst,
 input wire issue,input wire [3:0] capture_delay,input wire [1:0] capture_slot,
 input wire [63:0] raw,
 output wire valid,input wire ready,output wire [127:0] data,
 output reg fault=0);
 reg issue_half=0;reg [3:0] delay_half=0;reg [1:0] slot_half=0;
 always @(negedge clk_div) begin
  if(rst)begin issue_half<=0;delay_half<=0;slot_half<=0;end
  else begin issue_half<=issue;delay_half<=capture_delay;slot_half<=capture_slot;end
 end
 reg active=0,pending=0;reg [3:0] countdown=0;
 reg [1:0] slot=0,beat=0;reg [127:0] window_data=0,packet=0;
 wire full,empty,wr_busy,rd_busy;
 always @(posedge read_clk_div) begin
  if(rst)begin active<=0;pending<=0;fault<=0;countdown<=0;beat<=0;window_data<=0;packet<=0;slot<=0;end
  else begin
   pending<=0;
   if(pending && (full || wr_busy))fault<=1;
   if(issue_half)begin
    if(active || pending)fault<=1;
    active<=1;countdown<=delay_half;slot<=slot_half;beat<=0;
   end else if(active)begin
    if(countdown!=0)countdown<=countdown-1'b1;
    else if(beat==2)begin
     packet<=({raw,window_data} >> {slot,4'b0000});
     pending<=1;active<=0;
    end else begin
     if(beat==0)window_data[63:0]<=raw;
     else window_data[127:64]<=raw;
     beat<=beat+1'b1;
    end
   end
  end
 end
 assign valid=!empty && !rd_busy;
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("distributed"),.FIFO_WRITE_DEPTH(16),
  .WRITE_DATA_WIDTH(128),.READ_DATA_WIDTH(128),.READ_MODE("fwft"),
  .FIFO_READ_LATENCY(0),.CDC_SYNC_STAGES(2),.USE_ADV_FEATURES("0000"),
  .DOUT_RESET_VALUE("0"),.ECC_MODE("no_ecc")) responses(
  .rst(rst),.wr_clk(read_clk_div),.rd_clk(clk_div),.din(packet),
  .wr_en(pending && !full && !wr_busy),.dout(data),.rd_en(ready && valid),
  .full(full),.empty(empty),.wr_rst_busy(wr_busy),.rd_rst_busy(rd_busy),
  .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0),
  .almost_empty(),.almost_full(),.data_valid(),.dbiterr(),.sbiterr(),
  .overflow(),.underflow(),.prog_empty(),.prog_full(),.rd_data_count(),
  .wr_data_count(),.wr_ack());
endmodule
