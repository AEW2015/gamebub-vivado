`timescale 1ns/1ps
module tb_contract;
 reg clk=0,rst=0,stop_n=1;always #(500000000.0/29361979.0) clk=~clk;
 reg [31:0] aw=0,ar=0,wd=0;reg av=0,wv=0,bready=0,rv=0,rready=0;
 wire awready,wready,bvalid,arready,rvalid;wire [1:0] br,rr;wire [31:0] rd;
 wire mclk,bclk,wclk,din;
 gamebub_dac_audio dut(.audio_clk(clk),.audio_resetn(rst),.stop_n(stop_n),
 .dac_mclk(mclk),.dac_bclk(bclk),.dac_wclk(wclk),.dac_din(din),
 .S_AXI_awaddr(aw),.S_AXI_awprot(3'b0),.S_AXI_awvalid(av),.S_AXI_awready(awready),
 .S_AXI_wdata(wd),.S_AXI_wstrb(4'hf),.S_AXI_wvalid(wv),.S_AXI_wready(wready),
 .S_AXI_bresp(br),.S_AXI_bvalid(bvalid),.S_AXI_bready(bready),
 .S_AXI_araddr(ar),.S_AXI_arprot(3'b0),.S_AXI_arvalid(rv),.S_AXI_arready(arready),
 .S_AXI_rdata(rd),.S_AXI_rresp(rr),.S_AXI_rvalid(rvalid),.S_AXI_rready(rready));
 reg [31:0] value;reg [1:0] response;
 task read32(input [31:0] addr);
 begin
  @(negedge clk);ar=addr;rv=1;rready=0;
  @(posedge clk);while(!arready) @(posedge clk);
  @(negedge clk);rv=0;
  while(!rvalid) @(negedge clk);
  value=rd;response=rr;
  repeat(2) begin @(negedge clk);if(!rvalid || rd!==value || rr!==response) $fatal(1,"unstable R");end
  rready=1;@(negedge clk);rready=0;
 end endtask
 task write32(input [31:0] addr,input [31:0] data,input [1:0] expected);
 begin
  @(negedge clk);aw=addr;av=1;bready=0;
  @(posedge clk);while(!awready)@(posedge clk);
  @(negedge clk);av=0;repeat(2)@(negedge clk);wd=data;wv=1;
  @(posedge clk);while(!wready)@(posedge clk);
  @(negedge clk);wv=0;while(!bvalid)@(negedge clk);
  if(br!==expected)$fatal(1,"bad write addr%x resp%0d expected%0d",addr,br,expected);
  repeat(2)begin @(negedge clk);if(!bvalid || br!==expected)$fatal(1,"unstable B");end
  bready=1;@(negedge clk);bready=0;
 end endtask
 task expect_running(input bit expected);
 begin read32(8);if(value[0]!==expected)$fatal(1,"running expected%0d got%x",expected,value);end endtask
 initial begin
  repeat(5)@(negedge clk);rst=1;repeat(6)@(negedge clk);
  read32(0);if(value!==32'h53504b01 || response)$fatal(1,"ID");
  read32(24);if(value!==29361979 || response)$fatal(1,"clock");
  expect_running(0);read32(1);if(response!==2)$fatal(1,"misaligned read");
  write32(0,0,2);write32(4,3,2);write32(16,0,2);
  write32(32,0,0);write32(4,1,2); // staged invalid configuration cannot start
  write32(32,440,0);write32(36,5,0);write32(40,0,0);write32(44,0,0);write32(48,100,0);
  write32(4,1,0);expect_running(1);write32(32,880,2); // running writes prohibited
  write32(4,2,0);expect_running(0);
  write32(4,1,0);expect_running(1);stop_n=0;repeat(5)@(negedge clk);
  read32(8);if(value[0] || value[6:4]!==3)$fatal(1,"physical stop");stop_n=1;
  repeat(5)@(negedge clk);write32(4,1,0);expect_running(1);
  // Full nominal timer:100ms at CLOCK_HZ29361979, no accelerated/forced ticks.
  wait(!dut.audio.engine.running);read32(8);if(value[6:4]!==4)$fatal(1,"duration reason");
  write32(48,600,0);write32(4,1,0);expect_running(1);
  // Keep alive past initial lease; then intentionally omit heartbeat.
  repeat(29361*300) @(posedge clk);write32(16,32'h53504b31,0);
  repeat(29361*250) @(posedge clk);expect_running(1);
  // Extend session limit before start, not while running. Current total600ms wins before refreshed lease.
  wait(!dut.audio.engine.running);read32(8);if(value[6:4]!==4)$fatal(1,"heartbeat extended total limit");
  write32(48,1000,0);write32(4,1,0);expect_running(1);
  wait(!dut.audio.engine.running);read32(8);if(value[6:4]!==2)$fatal(1,"lease reason");
  $display("AUDIO_EXACT_RTL_PASS nominal_clock registers stalled_axi invalid_start stop physical_stop duration heartbeat lease");$finish;
 end
 initial begin #2000000000;$fatal(1,"test timeout");end
endmodule
