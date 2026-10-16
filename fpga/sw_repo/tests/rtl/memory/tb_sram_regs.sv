`timescale 1ns/1ps
module tb_sram_regs;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0;
 reg [11:0] s_axi_awaddr=0,s_axi_araddr=0;
 reg s_axi_awvalid=0,s_axi_wvalid=0,s_axi_bready=0,s_axi_arvalid=0,s_axi_rready=0;
 wire s_axi_awready,s_axi_wready,s_axi_bvalid,s_axi_arready,s_axi_rvalid;
 reg [31:0] s_axi_wdata=0;reg [3:0] s_axi_wstrb=15;
 wire [31:0] s_axi_rdata;wire [1:0] s_axi_bresp,s_axi_rresp;
 reg [2047:0] status=0;reg [255:0] active=0;
 reg armed=0,applying=0,quiescent=1,fault=0;
 wire [6:0] command;wire [255:0] requested;
 integer pulses=0;reg [6:0] last_command=0;
 sram_shared_test_regs dut(.*);
 always @(posedge clk)if(command!=0)begin pulses<=pulses+1;last_command<=command;end
 task wr(input [11:0] a,input [31:0] v,input [1:0] response);
 begin
  @(negedge clk);s_axi_awaddr=a;s_axi_awvalid=1;
  do @(posedge clk);while(!s_axi_awready);
  @(negedge clk);s_axi_awvalid=0;repeat(2)@(negedge clk);
  s_axi_wdata=v;s_axi_wvalid=1;
  do @(posedge clk);while(!s_axi_wready);
  @(negedge clk);s_axi_wvalid=0;wait(s_axi_bvalid);
  repeat(3)begin @(negedge clk);if(!s_axi_bvalid || s_axi_bresp!==response)$fatal(1,"SRAM B %x",s_axi_bresp);end
  s_axi_bready=1;@(negedge clk);s_axi_bready=0;
 end endtask
 task rd(input [11:0] a,input [31:0] v,input [1:0] response);
 begin
  @(negedge clk);s_axi_araddr=a;s_axi_arvalid=1;
  do @(posedge clk);while(!s_axi_arready);
  @(negedge clk);s_axi_arvalid=0;wait(s_axi_rvalid);
  repeat(3)begin @(negedge clk);if(!s_axi_rvalid || s_axi_rresp!==response || s_axi_rdata!==v)$fatal(1,"SRAM R addr=%x got=%x wanted=%x resp=%x",a,s_axi_rdata,v,s_axi_rresp);end
  s_axi_rready=1;@(negedge clk);s_axi_rready=0;
 end endtask
 initial begin
  repeat(4)@(negedge clk);rst_n=1;
  rd(0,32'h53524802,0);rd(16,32'h0003011f,0);rd(20,262144,0);
  wr(4,0,2);wr(4,3,2);wr(4,128,2);
  status[48*32+:32]=4;status[5*32+:32]=19;
  wr(4,16,0);rd(12,1,0);rd('h114,19,0);status[5*32+:32]=20;rd('h114,19,0);
  wr('h20,262143,0);wr('h24,2,0);wr(4,4,2);
  wr('h24,1,0);wr(4,4,0);
  if(requested[31:0]!==262143 || requested[63:32]!==1)$fatal(1,"SRAM apply capture");
  armed=1;wr(4,1,2);wr(4,8,2);armed=0;
  applying=1;wr(4,4,2);applying=0;
  wr(4,1,0);wr(4,2,0);
  rd('h200,0,2);rd('h021,0,2);
  if(pulses!=4)$fatal(1,"SRAM accepted pulse count %0d",pulses);
  $display("MEMORY_SRAM_REGS_PASS identity onehot snapshot range busy backpressure");$finish;
 end
 initial begin #100000;$fatal(1,"SRAM register watchdog");end
endmodule
