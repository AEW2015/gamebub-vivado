`timescale 1ns/1ps
// Two 4-KiB register banks behind one 8-KiB AXI-Lite slave. Absolute AXI
// addresses are decoded by bit 12; the interconnect owns the 8-KiB aperture.
// One outstanding write and one read, with independent AW/W capture and
// independent read/write backpressure. Payload and destination stay latched.
module s4_ctrl_router(
 input wire clk,resetn,output wire control_idle,
 input wire [31:0] s_awaddr,input wire [2:0] s_awprot,
 input wire s_awvalid,output wire s_awready,
 input wire [31:0] s_wdata,input wire [3:0] s_wstrb,
 input wire s_wvalid,output wire s_wready,
 output wire [1:0] s_bresp,output wire s_bvalid,input wire s_bready,
 input wire [31:0] s_araddr,input wire [2:0] s_arprot,
 input wire s_arvalid,output wire s_arready,
 output wire [31:0] s_rdata,output wire [1:0] s_rresp,
 output wire s_rvalid,input wire s_rready,
 output wire [63:0] m_awaddr,output wire [5:0] m_awprot,
 output wire [1:0] m_awvalid,input wire [1:0] m_awready,
 output wire [63:0] m_wdata,output wire [7:0] m_wstrb,
 output wire [1:0] m_wvalid,input wire [1:0] m_wready,
 input wire [3:0] m_bresp,input wire [1:0] m_bvalid,output wire [1:0] m_bready,
 output wire [63:0] m_araddr,output wire [5:0] m_arprot,
 output wire [1:0] m_arvalid,input wire [1:0] m_arready,
 input wire [63:0] m_rdata,input wire [3:0] m_rresp,
 input wire [1:0] m_rvalid,output wire [1:0] m_rready
);
 reg aw_full=0,w_full=0,wr_active=0,aw_sent=0,w_sent=0;
 reg [31:0] aw=0,wd=0;reg [2:0] ap=0;reg [3:0] ws=0;
 reg rd_active=0,ar_sent=0;reg [31:0] ar=0;reg [2:0] rp=0;
 wire wsel=aw[12],rsel=ar[12];
 wire write_error=ap[2],read_error=rp[2];
 assign s_awready=resetn && !aw_full && !wr_active;
 assign s_wready=resetn && !w_full && !wr_active;
 assign s_arready=resetn && !rd_active;
 assign s_bvalid=resetn && wr_active && (write_error || (aw_sent && w_sent && m_bvalid[wsel]));
 assign s_bresp=write_error?2'b10:m_bresp[2*wsel+:2];
 assign s_rvalid=resetn && rd_active && (read_error || (ar_sent && m_rvalid[rsel]));
 assign s_rresp=read_error?2'b10:m_rresp[2*rsel+:2];
 assign s_rdata=read_error?32'b0:m_rdata[32*rsel+:32];
 // Pending lower-bank control traffic participates in memory PARK safety.
 // Clock-bank accesses must not inhibit their own safe-apply handshake.
 assign control_idle=resetn && !(aw_full && !wsel) && !(w_full && !aw_full)
  && !(rd_active && !rsel) && !(s_awvalid && !s_awaddr[12])
  && !(s_arvalid && !s_araddr[12]);
 for(genvar i=0;i<2;i++)begin:bank
  assign m_awaddr[32*i+:32]={20'b0,aw[11:0]};
  assign m_awprot[3*i+:3]=ap;
  assign m_wdata[32*i+:32]=wd;
  assign m_wstrb[4*i+:4]=ws;
  assign m_awvalid[i]=resetn && wr_active && !write_error && wsel==i && !aw_sent;
  assign m_wvalid[i]=resetn && wr_active && !write_error && wsel==i && !w_sent;
  assign m_bready[i]=resetn && wr_active && !write_error && wsel==i && aw_sent && w_sent && s_bready;
  assign m_araddr[32*i+:32]={20'b0,ar[11:0]};
  assign m_arprot[3*i+:3]=rp;
  assign m_arvalid[i]=resetn && rd_active && !read_error && rsel==i && !ar_sent;
  assign m_rready[i]=resetn && rd_active && !read_error && rsel==i && ar_sent && s_rready;
 end
 always @(posedge clk)begin
  if(!resetn)begin
   aw_full<=0;w_full<=0;wr_active<=0;aw_sent<=0;w_sent<=0;rd_active<=0;ar_sent<=0;
   aw<=0;wd<=0;ap<=0;ws<=0;ar<=0;rp<=0;
  end else begin
   if(s_awvalid && s_awready)begin aw<=s_awaddr;ap<=s_awprot;aw_full<=1;end
   if(s_wvalid && s_wready)begin wd<=s_wdata;ws<=s_wstrb;w_full<=1;end
   if(aw_full && w_full && !wr_active)begin wr_active<=1;aw_sent<=0;w_sent<=0;end
   if(|(m_awvalid & m_awready))aw_sent<=1;
   if(|(m_wvalid & m_wready))w_sent<=1;
   if(s_bvalid && s_bready)begin wr_active<=0;aw_full<=0;w_full<=0;aw_sent<=0;w_sent<=0;end
   if(s_arvalid && s_arready)begin ar<=s_araddr;rp<=s_arprot;rd_active<=1;ar_sent<=0;end
   if(|(m_arvalid & m_arready))ar_sent<=1;
   if(s_rvalid && s_rready)begin rd_active<=0;ar_sent<=0;end
  end
 end
endmodule
