`timescale 1ns/1ps
module gamebub_esp32_irq #(
parameter integer C_SYNC_STAGES=2, C_MANUAL_OVERRIDE=0
)(
input wire irq_clk,irq_resetn,irq_request,output wire irq_gate,
input wire [31:0] S_AXI_awaddr,
input wire [2:0] S_AXI_awprot,
input wire S_AXI_awvalid,
output wire S_AXI_awready,
input wire [31:0] S_AXI_wdata,
input wire [3:0] S_AXI_wstrb,
input wire S_AXI_wvalid,
output wire S_AXI_wready,
output wire [1:0] S_AXI_bresp,
output wire S_AXI_bvalid,
input wire S_AXI_bready,
input wire [31:0] S_AXI_araddr,
input wire [2:0] S_AXI_arprot,
input wire S_AXI_arvalid,
output wire S_AXI_arready,
output wire [31:0] S_AXI_rdata,
output wire [1:0] S_AXI_rresp,
output wire S_AXI_rvalid,
input wire S_AXI_rready
);
(* ASYNC_REG="TRUE" *) reg [C_SYNC_STAGES-1:0] sync=0;
reg manual=0; reg aw_seen=0,w_seen=0;reg [31:0] aw=0,wd=0;reg [3:0] ws=0;
reg bvalid=0,rvalid=0;reg [1:0] bresp=0,rresp=0;reg [31:0] rdata=0;
assign S_AXI_awready=irq_resetn&&!aw_seen&&!bvalid;
assign S_AXI_wready=irq_resetn&&!w_seen&&!bvalid;
assign S_AXI_arready=irq_resetn&&!rvalid;
assign S_AXI_bvalid=bvalid;assign S_AXI_bresp=bresp;
assign S_AXI_rvalid=rvalid;assign S_AXI_rresp=rresp;assign S_AXI_rdata=rdata;
wire asserted=irq_resetn && (sync[C_SYNC_STAGES-1] || (C_MANUAL_OVERRIDE && manual));
// Rev4 has an external nFET: GATE=1 asserts the ESP32 active-low interrupt.
OBUF driver(.O(irq_gate),.I(asserted));
always @(posedge irq_clk or negedge irq_resetn)begin
 if(!irq_resetn)begin sync<=0;manual<=0;aw_seen<=0;w_seen<=0;bvalid<=0;rvalid<=0;bresp<=0;rresp<=0;rdata<=0;end
 else begin
  sync<={sync[C_SYNC_STAGES-2:0],irq_request};
  if(S_AXI_awvalid&&S_AXI_awready)begin aw_seen<=1;aw<=S_AXI_awaddr;end
  if(S_AXI_wvalid&&S_AXI_wready)begin w_seen<=1;wd<=S_AXI_wdata;ws<=S_AXI_wstrb;end
  if(bvalid&&S_AXI_bready)bvalid<=0;
  if(aw_seen&&w_seen&&!bvalid)begin
   aw_seen<=0;w_seen<=0;bvalid<=1;bresp<=0;
   if(aw[11:0]==4 && ws[0] && C_MANUAL_OVERRIDE)manual<=wd[0];else bresp<=2;
  end
  if(rvalid&&S_AXI_rready)rvalid<=0;
  if(S_AXI_arvalid&&S_AXI_arready)begin
   rvalid<=1;rresp<=0;rdata<=0;
   case(S_AXI_araddr[11:0])
    0:rdata<=32'h47424952;
    4:rdata<={31'd0,manual};
    8:rdata<={29'd0,asserted,sync[C_SYNC_STAGES-1],irq_request};
    12:rdata<=C_MANUAL_OVERRIDE;
    default:rresp<=2;
   endcase
  end
 end
end
endmodule
