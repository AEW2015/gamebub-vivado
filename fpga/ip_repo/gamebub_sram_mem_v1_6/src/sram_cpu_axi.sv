`timescale 1ns/1ps
// Single outstanding AXI4-Lite transaction; 32-bit little-endian -> 16-bit SRAM.
// Addresses are byte offsets within the aperture, not full system addresses.
module sram_cpu_axi(
 input wire clk,rst_n,enabled,
 input wire [31:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata,output reg [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready,
 output wire idle,output wire req_valid,input wire req_ready,
 output wire req_write,output wire [17:0] req_addr,output wire [15:0] req_data,output wire [1:0] req_be,
 input wire rsp_valid,output wire rsp_ready,input wire [15:0] rsp_data,input wire rsp_error);
 localparam COLLECT=0,ISSUE=1,WAIT_REPLY=2,COMPLETE=3;
 reg [1:0] state;
 reg have_aw,have_w,have_ar,denied,writing,half;
 reg [31:0] address,wdata;reg [3:0] strobes;
 wire collecting=state==COLLECT && !s_axi_bvalid && !s_axi_rvalid;
 assign s_axi_awready=rst_n && collecting && !have_aw && !have_ar;
 assign s_axi_wready=rst_n && collecting && !have_w && !have_ar;
 // Writes win only when both kinds arrive together; no combinational READY loop.
 assign s_axi_arready=rst_n && collecting && !have_aw && !have_w && !have_ar && !s_axi_awvalid && !s_axi_wvalid;
 assign idle=collecting && !have_aw && !have_w && !have_ar;
 wire [1:0] lanes=half?strobes[3:2]:strobes[1:0];
 assign req_valid=state==ISSUE && (!writing || lanes!=0);
 assign req_write=writing;
 assign req_addr={address[18:2],half};
 assign req_data=half?wdata[31:16]:wdata[15:0];
 assign req_be=writing?lanes:2'b11;
 assign rsp_ready=state==WAIT_REPLY;
 always @(posedge clk)begin
  if(!rst_n)begin
   state<=COLLECT;have_aw<=0;have_w<=0;have_ar<=0;denied<=0;writing<=0;half<=0;
   address<=0;wdata<=0;strobes<=0;s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rresp<=0;s_axi_rdata<=0;
  end else begin
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_awvalid && s_axi_awready)begin
    have_aw<=1;address<=s_axi_awaddr;
    if(!have_w)denied<=!enabled;
   end
   if(s_axi_wvalid && s_axi_wready)begin
    have_w<=1;wdata<=s_axi_wdata;strobes<=s_axi_wstrb;
    if(!have_aw)denied<=!enabled;
   end
   if(s_axi_arvalid && s_axi_arready)begin have_ar<=1;address<=s_axi_araddr;denied<=!enabled;end
   case(state)
    COLLECT:if(have_ar || (have_aw && have_w))begin
     writing<=!have_ar;half<=0;s_axi_rdata<=0;s_axi_rresp<=0;s_axi_bresp<=0;
     have_ar<=0;have_aw<=0;have_w<=0;
     // AXI-Lite returns the containing word. Byte addresses use WSTRB/read
     // lane selection in the master; transactions never cross a word boundary.
     if(denied || address[31:19]!=0)begin
      s_axi_rresp<=2'b10;s_axi_bresp<=2'b10;state<=COMPLETE;
     end else state<=ISSUE;
    end
    ISSUE:if(writing && lanes==0)begin
     if(half)state<=COMPLETE;else half<=1;
    end else if(req_ready)state<=WAIT_REPLY;
    WAIT_REPLY:if(rsp_valid)begin
     if(!writing)begin
      if(half)s_axi_rdata[31:16]<=rsp_data;else s_axi_rdata[15:0]<=rsp_data;
     end
     if(rsp_error)begin s_axi_rresp<=2'b10;s_axi_bresp<=2'b10;state<=COMPLETE;end
     else if(half)state<=COMPLETE;
     else begin half<=1;state<=ISSUE;end
    end
    COMPLETE:begin
     if(writing)s_axi_bvalid<=1;else s_axi_rvalid<=1;
     state<=COLLECT;
    end
   endcase
  end
 end
endmodule
