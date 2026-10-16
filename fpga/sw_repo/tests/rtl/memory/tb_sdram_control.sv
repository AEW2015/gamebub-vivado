`timescale 1ns/1ps
module tb_sdram_control;
 reg aclk=0;always #5 aclk=~aclk;
 reg aresetn=0;
 reg [31:0] s_axi_awaddr=0,s_axi_araddr=0,s_axi_wdata=0;
 reg [2:0] s_axi_awprot=0,s_axi_arprot=0;reg [3:0] s_axi_wstrb=15;
 reg s_axi_awvalid=0,s_axi_wvalid=0,s_axi_bready=0,s_axi_arvalid=0,s_axi_rready=0;
 wire s_axi_awready,s_axi_wready,s_axi_bvalid,s_axi_arready,s_axi_rvalid;
 wire [31:0] s_axi_rdata;wire [1:0] s_axi_bresp,s_axi_rresp;
 reg link_busy=0,link_error=0,link_fault=0;
 wire link_complete;wire [1279:0] link_response;
 wire link_send,link_recover,idle;wire [431:0] link_request;
 reg initialized=1,delay_ready=1,fatal=0;
 reg [1151:0] telemetry=0;reg [79:0] tap_actual=0;
 wire [351:0] configuration;wire start,abort_run,tap_load,parked;
 reg test_valid=0,test_write=0,test_rsp_ready=0;reg [23:0] test_addr=0;reg [127:0] test_data=0;reg [15:0] test_mask=0;
 wire test_ready,test_rsp_valid;wire [127:0] test_rsp_data;wire [2:0] test_rsp_status;
 wire req_valid,req_write,rsp_ready;wire [23:0] req_addr;wire [127:0] req_data;wire [15:0] req_mask;
 reg req_ready=1,rsp_valid=0;reg [127:0] rsp_data=0;reg [2:0] rsp_status=0;
 s4_shared_axi dut(.*);
 s4_shared_backend backend(.clk_div(aclk),.rst(!aresetn),.mem_valid(link_send),.mem_data(link_request),
 .mem_done(link_complete),.mem_response(link_response),.*);
 task wr(input [31:0] a,input [31:0] v,input [1:0] response);
 begin
  @(negedge aclk);s_axi_awaddr=a;s_axi_awvalid=1;
  do @(posedge aclk);while(!s_axi_awready);
  @(negedge aclk);s_axi_awvalid=0;repeat(2)@(negedge aclk);
  s_axi_wdata=v;s_axi_wvalid=1;do @(posedge aclk);while(!s_axi_wready);
  @(negedge aclk);s_axi_wvalid=0;wait(s_axi_bvalid);
  repeat(3)begin @(negedge aclk);if(!s_axi_bvalid || s_axi_bresp!==response)$fatal(1,"SDRAM B %x",s_axi_bresp);end
  s_axi_bready=1;@(negedge aclk);s_axi_bready=0;
 end endtask
 task rd(input [31:0] a,input [31:0] v,input [1:0] response);
 begin
  @(negedge aclk);s_axi_araddr=a;s_axi_arvalid=1;do @(posedge aclk);while(!s_axi_arready);
  @(negedge aclk);s_axi_arvalid=0;wait(s_axi_rvalid);
  repeat(3)begin @(negedge aclk);if(!s_axi_rvalid || s_axi_rresp!==response || s_axi_rdata!==v)$fatal(1,"SDRAM R a=%x got=%x wanted=%x resp=%x",a,s_axi_rdata,v,s_axi_rresp);end
  s_axi_rready=1;@(negedge aclk);s_axi_rready=0;
 end endtask
 localparam C=32'h62000000;
 initial begin
  telemetry[10]=1;telemetry[11]=1;telemetry[7]=1;
  repeat(4)@(negedge aclk);aresetn=1;
  rd(C,32'h53345331,0);rd(C+16,32'h02000000,0);rd(C+20,1,0);
  wr(C+4,1,2);wr(C+4,8,2);rd(C+12,0,0);
  wr(C+'h4c,32'h40000000,0);wr(C+4,3,0);rd(C+8,4,0);
  wr(C+'h4c,32'h80000000,0);wr(C+4,3,0);rd(C+8,8,0);
  wr(C+4,4,0);
  telemetry[0]=1;telemetry[10]=0;
  wr(C+'h4c,0,0);wr(C+4,3,2);rd(C+8,8,0);
  telemetry[0]=0;telemetry[10]=1;
  wr(C+4,3,0);rd(C+8,0,0);
  tap_actual=80'hf123456789abcdef1234;wr(C+4,7,0);rd(C+'h190,32'hcdef1234,0);
  fatal=1;wr(C+'h4c,32'h40000000,0);wr(C+4,3,2);fatal=0;
  s_axi_arprot=4;rd(C,0,2);s_axi_arprot=0;rd(C+1,0,2);rd(C+'h200,0,3);
  $display("MEMORY_SDRAM_CONTROL_PASS identity ownership busy_rejection snapshot taps protection backpressure");$finish;
 end
 initial begin #100000;$fatal(1,"SDRAM control watchdog");end
endmodule
