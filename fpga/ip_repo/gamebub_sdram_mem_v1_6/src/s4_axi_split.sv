`timescale 1ns/1ps
// Fair, serialized two-source AXI-Lite adapter. Upstream retains request payload
// until handshake; independent AW/W acceptance is tracked, never duplicated.
module s4_axi_split #(parameter [31:0] BASE_ADDR=32'h60000000)(
 input wire clk,resetn,output wire idle,
 input wire [31:0] mem_awaddr,
 input wire [2:0] mem_awprot,
 input wire  mem_awvalid,
 output wire  mem_awready,
 input wire [31:0] mem_wdata,
 input wire [3:0] mem_wstrb,
 input wire  mem_wvalid,
 output wire  mem_wready,
 output wire [1:0] mem_bresp,
 output wire  mem_bvalid,
 input wire  mem_bready,
 input wire [31:0] mem_araddr,
 input wire [2:0] mem_arprot,
 input wire  mem_arvalid,
 output wire  mem_arready,
 output wire [31:0] mem_rdata,
 output wire [1:0] mem_rresp,
 output wire  mem_rvalid,
 input wire  mem_rready,
 input wire [31:0] ctrl_awaddr,
 input wire [2:0] ctrl_awprot,
 input wire  ctrl_awvalid,
 output wire  ctrl_awready,
 input wire [31:0] ctrl_wdata,
 input wire [3:0] ctrl_wstrb,
 input wire  ctrl_wvalid,
 output wire  ctrl_wready,
 output wire [1:0] ctrl_bresp,
 output wire  ctrl_bvalid,
 input wire  ctrl_bready,
 input wire [31:0] ctrl_araddr,
 input wire [2:0] ctrl_arprot,
 input wire  ctrl_arvalid,
 output wire  ctrl_arready,
 output wire [31:0] ctrl_rdata,
 output wire [1:0] ctrl_rresp,
 output wire  ctrl_rvalid,
 input wire  ctrl_rready,
 output wire [31:0] m_awaddr,
 output wire [2:0] m_awprot,
 output wire  m_awvalid,
 input wire  m_awready,
 output wire [31:0] m_wdata,
 output wire [3:0] m_wstrb,
 output wire  m_wvalid,
 input wire  m_wready,
 input wire [1:0] m_bresp,
 input wire  m_bvalid,
 output wire  m_bready,
 output wire [31:0] m_araddr,
 output wire [2:0] m_arprot,
 output wire  m_arvalid,
 input wire  m_arready,
 input wire [31:0] m_rdata,
 input wire [1:0] m_rresp,
 input wire  m_rvalid,
 output wire  m_rready
);
reg active=0;
reg [1:0] selected=0,turn=0;
reg aw_done=0,w_done=0,ar_done=0;
wire source=selected[1],write_cycle=selected[0];
wire [3:0] request={ctrl_awvalid|ctrl_wvalid,ctrl_arvalid,mem_awvalid|mem_wvalid,mem_arvalid};
assign idle=!active && !(|request);
integer j,k; reg found;
always @(posedge clk)begin
 if(!resetn)begin active<=0;selected<=0;turn<=0;aw_done<=0;w_done<=0;ar_done<=0;end
 else if(!active)begin
  found=0;
  for(j=0;j<4;j=j+1)begin
   k=(turn+j)&3;
   if(!found && request[k])begin selected<=k;active<=1;found=1;end
  end
  aw_done<=0;w_done<=0;ar_done<=0;
 end else begin
  if(m_awvalid && m_awready)aw_done<=1;
  if(m_wvalid && m_wready)w_done<=1;
  if(m_arvalid && m_arready)ar_done<=1;
  if((write_cycle && m_bvalid && m_bready) || (!write_cycle && m_rvalid && m_rready))begin
   active<=0;turn<=selected+1'b1;
  end
 end
end
wire wr=active && write_cycle && resetn;
wire rd=active && !write_cycle && resetn;
wire [31:0] aw=source?ctrl_awaddr:mem_awaddr;
wire [31:0] ar=source?ctrl_araddr:mem_araddr;
// Public memory is exactly 32 MiB; private CSR decoder remains at +32 MiB.
assign m_awaddr=BASE_ADDR+(source?(32'h02000000+{20'b0,aw[11:0]}):{7'b0,aw[24:0]});
assign m_araddr=BASE_ADDR+(source?(32'h02000000+{20'b0,ar[11:0]}):{7'b0,ar[24:0]});
assign m_awprot=source?ctrl_awprot:mem_awprot;
assign m_arprot=source?ctrl_arprot:mem_arprot;
assign m_wdata=source?ctrl_wdata:mem_wdata;
assign m_wstrb=source?ctrl_wstrb:mem_wstrb;
assign m_awvalid=wr && !aw_done && (source?ctrl_awvalid:mem_awvalid);
assign m_wvalid=wr && !w_done && (source?ctrl_wvalid:mem_wvalid);
assign m_arvalid=rd && !ar_done && (source?ctrl_arvalid:mem_arvalid);
assign m_bready=wr && aw_done && w_done && (source?ctrl_bready:mem_bready);
assign m_rready=rd && ar_done && (source?ctrl_rready:mem_rready);
assign mem_awready=wr && !source && !aw_done && m_awready;
assign mem_wready=wr && !source && !w_done && m_wready;
assign mem_arready=rd && !source && !ar_done && m_arready;
assign mem_bvalid=wr && !source && aw_done && w_done && m_bvalid;
assign mem_rvalid=rd && !source && ar_done && m_rvalid;
assign mem_bresp=m_bresp;
assign mem_rresp=m_rresp;
assign mem_rdata=m_rdata;
assign ctrl_awready=wr && source && !aw_done && m_awready;
assign ctrl_wready=wr && source && !w_done && m_wready;
assign ctrl_arready=rd && source && !ar_done && m_arready;
assign ctrl_bvalid=wr && source && aw_done && w_done && m_bvalid;
assign ctrl_rvalid=rd && source && ar_done && m_rvalid;
assign ctrl_bresp=m_bresp;
assign ctrl_rresp=m_rresp;
assign ctrl_rdata=m_rdata;
endmodule
