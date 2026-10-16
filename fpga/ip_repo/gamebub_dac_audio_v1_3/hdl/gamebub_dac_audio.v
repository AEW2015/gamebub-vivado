`timescale 1ns/1ps
module gamebub_dac_audio #(
parameter integer C_DEFAULT_FREQUENCY=440,C_DEFAULT_LEVEL=10,C_DEFAULT_LIMIT_MS=5000
)(
input wire audio_clk,audio_resetn,stop_n,
output wire dac_mclk,dac_bclk,dac_wclk,dac_din,
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
speaker_peripheral #(.DEFAULT_FREQUENCY(C_DEFAULT_FREQUENCY),.DEFAULT_LEVEL(C_DEFAULT_LEVEL),
 .DEFAULT_LIMIT_MS(C_DEFAULT_LIMIT_MS)) audio(.clk(audio_clk),.rst_n(audio_resetn),.stop_n(stop_n),
 .dac_bclk(dac_bclk),.dac_wclk(dac_wclk),.dac_din(dac_din),
.s_axi_awaddr(S_AXI_awaddr[11:0]),
.s_axi_awvalid(S_AXI_awvalid),
.s_axi_awready(S_AXI_awready),
.s_axi_wdata(S_AXI_wdata),
.s_axi_wstrb(S_AXI_wstrb),
.s_axi_wvalid(S_AXI_wvalid),
.s_axi_wready(S_AXI_wready),
.s_axi_bresp(S_AXI_bresp),
.s_axi_bvalid(S_AXI_bvalid),
.s_axi_bready(S_AXI_bready),
.s_axi_araddr(S_AXI_araddr[11:0]),
.s_axi_arvalid(S_AXI_arvalid),
.s_axi_arready(S_AXI_arready),
.s_axi_rdata(S_AXI_rdata),
.s_axi_rresp(S_AXI_rresp),
.s_axi_rvalid(S_AXI_rvalid),
.s_axi_rready(S_AXI_rready));
ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) masterclock(.Q(dac_mclk),.C(audio_clk),.CE(1'b1),.D1(1'b1),.D2(1'b0),.R(1'b0),.S(1'b0));
endmodule
