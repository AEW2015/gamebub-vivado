`timescale 1ns/1ps
module gamebub_sdram_mem #(
parameter [31:0] C_BASE_ADDR=32'h60000000,
parameter integer C_POWER_BEATS=15625,C_TIMEOUT_CYCLES=131072,C_METER_WINDOW=100000
)(
input wire host_clk,host_resetn,refclk200,ref_resetn,reconfig_hold,
output wire memory_safe,reconfig_safe,link_fault,clock_ready,
output wire [12:0] sdram_a,output wire [1:0] sdram_bs,sdram_cke,sdram_cs_n,
output wire sdram_clk,sdram_we_n,sdram_ldqm,sdram_udqm,sdram_cas_n,sdram_ras_n,
inout wire [15:0] sdram_dq,
input wire [31:0] MEM_AXI_awaddr,
input wire [2:0] MEM_AXI_awprot,
input wire MEM_AXI_awvalid,
output wire MEM_AXI_awready,
input wire [31:0] MEM_AXI_wdata,
input wire [3:0] MEM_AXI_wstrb,
input wire MEM_AXI_wvalid,
output wire MEM_AXI_wready,
output wire [1:0] MEM_AXI_bresp,
output wire MEM_AXI_bvalid,
input wire MEM_AXI_bready,
input wire [31:0] MEM_AXI_araddr,
input wire [2:0] MEM_AXI_arprot,
input wire MEM_AXI_arvalid,
output wire MEM_AXI_arready,
output wire [31:0] MEM_AXI_rdata,
output wire [1:0] MEM_AXI_rresp,
output wire MEM_AXI_rvalid,
input wire MEM_AXI_rready,
input wire [31:0] CTRL_AXI_awaddr,
input wire [2:0] CTRL_AXI_awprot,
input wire CTRL_AXI_awvalid,
output wire CTRL_AXI_awready,
input wire [31:0] CTRL_AXI_wdata,
input wire [3:0] CTRL_AXI_wstrb,
input wire CTRL_AXI_wvalid,
output wire CTRL_AXI_wready,
output wire [1:0] CTRL_AXI_bresp,
output wire CTRL_AXI_bvalid,
input wire CTRL_AXI_bready,
input wire [31:0] CTRL_AXI_araddr,
input wire [2:0] CTRL_AXI_arprot,
input wire CTRL_AXI_arvalid,
output wire CTRL_AXI_arready,
output wire [31:0] CTRL_AXI_rdata,
output wire [1:0] CTRL_AXI_rresp,
output wire CTRL_AXI_rvalid,
input wire CTRL_AXI_rready
);
wire [31:0] REG_AXI_awaddr;
wire [2:0] REG_AXI_awprot;
wire REG_AXI_awvalid;
wire REG_AXI_awready;
wire [31:0] REG_AXI_wdata;
wire [3:0] REG_AXI_wstrb;
wire REG_AXI_wvalid;
wire REG_AXI_wready;
wire [1:0] REG_AXI_bresp;
wire REG_AXI_bvalid;
wire REG_AXI_bready;
wire [31:0] REG_AXI_araddr;
wire [2:0] REG_AXI_arprot;
wire REG_AXI_arvalid;
wire REG_AXI_arready;
wire [31:0] REG_AXI_rdata;
wire [1:0] REG_AXI_rresp;
wire REG_AXI_rvalid;
wire REG_AXI_rready;
wire [31:0] CLK_AXI_awaddr;
wire [2:0] CLK_AXI_awprot;
wire CLK_AXI_awvalid;
wire CLK_AXI_awready;
wire [31:0] CLK_AXI_wdata;
wire [3:0] CLK_AXI_wstrb;
wire CLK_AXI_wvalid;
wire CLK_AXI_wready;
wire [1:0] CLK_AXI_bresp;
wire CLK_AXI_bvalid;
wire CLK_AXI_bready;
wire [31:0] CLK_AXI_araddr;
wire [2:0] CLK_AXI_arprot;
wire CLK_AXI_arvalid;
wire CLK_AXI_arready;
wire [31:0] CLK_AXI_rdata;
wire [1:0] CLK_AXI_rresp;
wire CLK_AXI_rvalid;
wire CLK_AXI_rready;
s4_ctrl_router router(.clk(host_clk),.resetn(host_resetn),.control_idle(control_idle),
.s_awaddr(CTRL_AXI_awaddr),
.s_awprot(CTRL_AXI_awprot),
.s_awvalid(CTRL_AXI_awvalid),
.s_awready(CTRL_AXI_awready),
.s_wdata(CTRL_AXI_wdata),
.s_wstrb(CTRL_AXI_wstrb),
.s_wvalid(CTRL_AXI_wvalid),
.s_wready(CTRL_AXI_wready),
.s_bresp(CTRL_AXI_bresp),
.s_bvalid(CTRL_AXI_bvalid),
.s_bready(CTRL_AXI_bready),
.s_araddr(CTRL_AXI_araddr),
.s_arprot(CTRL_AXI_arprot),
.s_arvalid(CTRL_AXI_arvalid),
.s_arready(CTRL_AXI_arready),
.s_rdata(CTRL_AXI_rdata),
.s_rresp(CTRL_AXI_rresp),
.s_rvalid(CTRL_AXI_rvalid),
.s_rready(CTRL_AXI_rready),
.m_awaddr({CLK_AXI_awaddr,REG_AXI_awaddr}),
.m_awprot({CLK_AXI_awprot,REG_AXI_awprot}),
.m_awvalid({CLK_AXI_awvalid,REG_AXI_awvalid}),
.m_awready({CLK_AXI_awready,REG_AXI_awready}),
.m_wdata({CLK_AXI_wdata,REG_AXI_wdata}),
.m_wstrb({CLK_AXI_wstrb,REG_AXI_wstrb}),
.m_wvalid({CLK_AXI_wvalid,REG_AXI_wvalid}),
.m_wready({CLK_AXI_wready,REG_AXI_wready}),
.m_bresp({CLK_AXI_bresp,REG_AXI_bresp}),
.m_bvalid({CLK_AXI_bvalid,REG_AXI_bvalid}),
.m_bready({CLK_AXI_bready,REG_AXI_bready}),
.m_araddr({CLK_AXI_araddr,REG_AXI_araddr}),
.m_arprot({CLK_AXI_arprot,REG_AXI_arprot}),
.m_arvalid({CLK_AXI_arvalid,REG_AXI_arvalid}),
.m_arready({CLK_AXI_arready,REG_AXI_arready}),
.m_rdata({CLK_AXI_rdata,REG_AXI_rdata}),
.m_rresp({CLK_AXI_rresp,REG_AXI_rresp}),
.m_rvalid({CLK_AXI_rvalid,REG_AXI_rvalid}),
.m_rready({CLK_AXI_rready,REG_AXI_rready}));
wire frontend_idle,split_idle,control_idle;
assign frontend_idle=split_idle && control_idle;
wire [31:0] bus_awaddr;
wire [2:0] bus_awprot;
wire  bus_awvalid;
wire  bus_awready;
wire [31:0] bus_wdata;
wire [3:0] bus_wstrb;
wire  bus_wvalid;
wire  bus_wready;
wire [1:0] bus_bresp;
wire  bus_bvalid;
wire  bus_bready;
wire [31:0] bus_araddr;
wire [2:0] bus_arprot;
wire  bus_arvalid;
wire  bus_arready;
wire [31:0] bus_rdata;
wire [1:0] bus_rresp;
wire  bus_rvalid;
wire  bus_rready;
s4_axi_split #(.BASE_ADDR(C_BASE_ADDR)) split(.clk(host_clk),.resetn(host_resetn),.idle(split_idle),
.mem_awaddr(MEM_AXI_awaddr),.ctrl_awaddr(REG_AXI_awaddr),.m_awaddr(bus_awaddr),
.mem_awprot(MEM_AXI_awprot),.ctrl_awprot(REG_AXI_awprot),.m_awprot(bus_awprot),
.mem_awvalid(MEM_AXI_awvalid),.ctrl_awvalid(REG_AXI_awvalid),.m_awvalid(bus_awvalid),
.mem_awready(MEM_AXI_awready),.ctrl_awready(REG_AXI_awready),.m_awready(bus_awready),
.mem_wdata(MEM_AXI_wdata),.ctrl_wdata(REG_AXI_wdata),.m_wdata(bus_wdata),
.mem_wstrb(MEM_AXI_wstrb),.ctrl_wstrb(REG_AXI_wstrb),.m_wstrb(bus_wstrb),
.mem_wvalid(MEM_AXI_wvalid),.ctrl_wvalid(REG_AXI_wvalid),.m_wvalid(bus_wvalid),
.mem_wready(MEM_AXI_wready),.ctrl_wready(REG_AXI_wready),.m_wready(bus_wready),
.mem_bresp(MEM_AXI_bresp),.ctrl_bresp(REG_AXI_bresp),.m_bresp(bus_bresp),
.mem_bvalid(MEM_AXI_bvalid),.ctrl_bvalid(REG_AXI_bvalid),.m_bvalid(bus_bvalid),
.mem_bready(MEM_AXI_bready),.ctrl_bready(REG_AXI_bready),.m_bready(bus_bready),
.mem_araddr(MEM_AXI_araddr),.ctrl_araddr(REG_AXI_araddr),.m_araddr(bus_araddr),
.mem_arprot(MEM_AXI_arprot),.ctrl_arprot(REG_AXI_arprot),.m_arprot(bus_arprot),
.mem_arvalid(MEM_AXI_arvalid),.ctrl_arvalid(REG_AXI_arvalid),.m_arvalid(bus_arvalid),
.mem_arready(MEM_AXI_arready),.ctrl_arready(REG_AXI_arready),.m_arready(bus_arready),
.mem_rdata(MEM_AXI_rdata),.ctrl_rdata(REG_AXI_rdata),.m_rdata(bus_rdata),
.mem_rresp(MEM_AXI_rresp),.ctrl_rresp(REG_AXI_rresp),.m_rresp(bus_rresp),
.mem_rvalid(MEM_AXI_rvalid),.ctrl_rvalid(REG_AXI_rvalid),.m_rvalid(bus_rvalid),
.mem_rready(MEM_AXI_rready),.ctrl_rready(REG_AXI_rready),.m_rready(bus_rready));
wire cmd_clk,cmd_div,read_clk,read_div,locked,hold_active;
reg [4:0] hold_count=0;
always @(posedge host_clk)begin if(!host_resetn || !hold_active)hold_count<=0;else if(hold_count<16)hold_count<=hold_count+1'b1;end
assign reconfig_safe=hold_active && hold_count==16;
(* ASYNC_REG="TRUE" *) reg [3:0] delay_reset=15;
always @(posedge refclk200 or negedge ref_resetn)if(!ref_resetn)delay_reset<=15;else delay_reset<={delay_reset[2:0],1'b0};
serdes4_runtime_clocks #(.METER_WINDOW(C_METER_WINDOW)) clocks(.host_clk(host_clk),.rst_n(host_resetn),
 .reconfig_safe(reconfig_safe),.clk(cmd_clk),.clk_div(cmd_div),.read_clk(read_clk),.read_clk_div(read_div),
 .locked(locked),.clock_ready(clock_ready),
.s_axi_awaddr(CLK_AXI_awaddr[11:0]),
.s_axi_awvalid(CLK_AXI_awvalid),
.s_axi_awready(CLK_AXI_awready),
.s_axi_wdata(CLK_AXI_wdata),
.s_axi_wstrb(CLK_AXI_wstrb),
.s_axi_wvalid(CLK_AXI_wvalid),
.s_axi_wready(CLK_AXI_wready),
.s_axi_bresp(CLK_AXI_bresp),
.s_axi_bvalid(CLK_AXI_bvalid),
.s_axi_bready(CLK_AXI_bready),
.s_axi_araddr(CLK_AXI_araddr[11:0]),
.s_axi_arvalid(CLK_AXI_arvalid),
.s_axi_arready(CLK_AXI_arready),
.s_axi_rdata(CLK_AXI_rdata),
.s_axi_rresp(CLK_AXI_rresp),
.s_axi_rvalid(CLK_AXI_rvalid),
.s_axi_rready(CLK_AXI_rready));
s4_shared_top #(.BASE_ADDR(C_BASE_ADDR),.POWER_BEATS(C_POWER_BEATS),.TIMEOUT_CYCLES(C_TIMEOUT_CYCLES),.FRONTEND_GUARD(1)) memory(
 .aclk(host_clk),.aresetn(host_resetn),.clk(cmd_clk),.clk_div(cmd_div),.read_clk(read_clk),.read_clk_div(read_div),
 .refclk200(refclk200),.rst_delay(delay_reset[3]),.locked(locked),.reconfig_hold(reconfig_hold),
 .frontend_idle(frontend_idle),.hold_active(hold_active),.reconfig_safe(memory_safe),.link_fault(link_fault),
.s_axi_awaddr(bus_awaddr),
.s_axi_awprot(bus_awprot),
.s_axi_awvalid(bus_awvalid),
.s_axi_awready(bus_awready),
.s_axi_wdata(bus_wdata),
.s_axi_wstrb(bus_wstrb),
.s_axi_wvalid(bus_wvalid),
.s_axi_wready(bus_wready),
.s_axi_bresp(bus_bresp),
.s_axi_bvalid(bus_bvalid),
.s_axi_bready(bus_bready),
.s_axi_araddr(bus_araddr),
.s_axi_arprot(bus_arprot),
.s_axi_arvalid(bus_arvalid),
.s_axi_arready(bus_arready),
.s_axi_rdata(bus_rdata),
.s_axi_rresp(bus_rresp),
.s_axi_rvalid(bus_rvalid),
.s_axi_rready(bus_rready),
 .sdram_a(sdram_a),.sdram_bs(sdram_bs),.sdram_dq(sdram_dq),.sdram_clk(sdram_clk),
 .sdram_we_n(sdram_we_n),.sdram_ldqm(sdram_ldqm),.sdram_udqm(sdram_udqm),.sdram_cas_n(sdram_cas_n),
 .sdram_ras_n(sdram_ras_n),.sdram_cke(sdram_cke),.sdram_cs_n(sdram_cs_n));
endmodule
