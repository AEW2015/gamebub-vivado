`timescale 1ns/1ps
// Fixed serializer clock tree: 100 MHz CLKDIV and 400 MHz DDR I/O.
module sram_clock_tree(input wire clk,rst_n,request,input wire [2:0] profile,
 output wire mem_clk,io_clk,mem_rst_n,ready,busy,fault,output wire [2:0] selected);
 wire fb,fbb,locked,mmcm_reset,raw100,raw400;
 // 100 MHz host -> 800 MHz VCO -> unchanged 400/100 MHz PHY clocks.
 MMCME2_BASE #(.CLKIN1_PERIOD(10.0),.CLKFBOUT_MULT_F(8.0),.DIVCLK_DIVIDE(1),
  .CLKOUT0_DIVIDE_F(2.0),.CLKOUT1_DIVIDE(8))
 mmcm(.CLKIN1(clk),.CLKFBIN(fbb),.CLKFBOUT(fb),.CLKOUT0(raw400),.CLKOUT1(raw100),.LOCKED(locked),.PWRDWN(1'b0),.RST(mmcm_reset));
 BUFG feedback(.I(fb),.O(fbb));
 BUFG scheduler_buffer(.I(raw100),.O(mem_clk));
 BUFG io_buffer(.I(raw400),.O(io_clk));
 // Local host-domain reset driver: do not route the system-wide reset inverter
 // directly into the 400 MHz synchronizer. Preserve asynchronous assertion;
 // release the local copy on a host edge, then synchronize it in the I/O domain.
 // DONT_TOUCH prevents folding this low-fanout reset stage back into host reset.
 // Active-high local reset drives FDCE.CLR directly, removing the 100->400MHz
 // reset inverter. Host assertion remains asynchronous; local release and the
 // three I/O-domain release stages retain the same external behavior.
 (* DONT_TOUCH="TRUE" *) reg heart_local_reset=1;
 always @(posedge clk or negedge rst_n)
  if(!rst_n)heart_local_reset<=1;else heart_local_reset<=0;
 (* ASYNC_REG="TRUE" *) reg [2:0] heart_reset_sync=0;
 always @(posedge io_clk or posedge heart_local_reset)if(heart_local_reset)heart_reset_sync<=0;else heart_reset_sync<={heart_reset_sync[1:0],1'b1};
 wire heart_rst_n=heart_reset_sync[2];
 reg [3:0] heart_count=0;
 always @(posedge io_clk or negedge heart_rst_n)if(!heart_rst_n)heart_count<=0;else heart_count<=heart_count+1'b1;
 sram_clock_control #(.CLOCK_HZ(100000000)) control(.clk(clk),.rst_n(rst_n),.request(request),.profile(3'd0),.locked(locked),.heartbeat(heart_count[3]),.selected(selected),.mmcm_reset(mmcm_reset),.ready(ready),.busy(busy),.fault(fault));
 (* ASYNC_REG="TRUE" *) reg [2:0] reset_sync=0;
 wire run_resetn=rst_n && ready;
 always @(posedge mem_clk or negedge run_resetn)if(!run_resetn)reset_sync<=0;else reset_sync<={reset_sync[1:0],1'b1};
 assign mem_rst_n=reset_sync[2];
endmodule


