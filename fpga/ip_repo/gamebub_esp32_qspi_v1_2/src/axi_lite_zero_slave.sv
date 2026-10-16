`timescale 1ns/1ps
// Safe terminator for an intentionally absent AXI-Lite peripheral. Reads
// return zero and writes complete successfully so an optional service cannot
// occupy the shared interconnect forever.
module axi_lite_zero_slave(
 input wire clk,resetn,
 input wire [31:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready);
 reg aw_seen=0,w_seen=0;
 assign s_axi_awready=resetn&&!aw_seen&&!s_axi_bvalid;
 assign s_axi_wready=resetn&&!w_seen&&!s_axi_bvalid;
 assign s_axi_bresp=2'b00;
 assign s_axi_arready=resetn&&!s_axi_rvalid;
 assign s_axi_rdata=32'd0;
 assign s_axi_rresp=2'b00;
 always @(posedge clk) begin
  if(!resetn) begin aw_seen<=0;w_seen<=0;s_axi_bvalid<=0;s_axi_rvalid<=0;end
  else begin
   if(s_axi_awready&&s_axi_awvalid)aw_seen<=1;
   if(s_axi_wready&&s_axi_wvalid)w_seen<=1;
   if(!s_axi_bvalid&&(aw_seen||(s_axi_awready&&s_axi_awvalid))&&(w_seen||(s_axi_wready&&s_axi_wvalid))) begin
    aw_seen<=0;w_seen<=0;s_axi_bvalid<=1;
   end else if(s_axi_bvalid&&s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_arready&&s_axi_arvalid)s_axi_rvalid<=1;
   else if(s_axi_rvalid&&s_axi_rready)s_axi_rvalid<=0;
  end
 end
 wire unused=&{1'b0,s_axi_awaddr,s_axi_wdata,s_axi_wstrb,s_axi_araddr};
endmodule
