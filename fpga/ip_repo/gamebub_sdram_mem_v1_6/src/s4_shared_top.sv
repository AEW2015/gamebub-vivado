`timescale 1ns/1ps
// Reusable subsystem: standard AXI-Lite on stable host clock, external SDRAM clocks.
// No CPU, LCD, SRAM, MMCM or configuration flash ownership is instantiated here.
module s4_shared_top #(parameter [31:0] BASE_ADDR=32'h60000000,
 parameter integer POWER_BEATS=15625,TIMEOUT_CYCLES=65536,FRONTEND_GUARD=0)(
 (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET aresetn" *)
 input wire aclk,
 (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *) input wire aresetn,
 input wire clk,clk_div,read_clk,read_clk_div,refclk200,rst_delay,locked,
 input wire frontend_idle,
 input wire reconfig_hold,output wire reconfig_safe,output reg hold_active=0,
 output wire link_fault,
 input wire [31:0] s_axi_awaddr,input wire [2:0] s_axi_awprot,
 input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,
 input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output wire s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire [2:0] s_axi_arprot,
 input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,
 output wire s_axi_rvalid,input wire s_axi_rready,
 output wire [12:0] sdram_a,output wire [1:0] sdram_bs,sdram_cke,sdram_cs_n,
 output wire sdram_ras_n,sdram_cas_n,sdram_we_n,sdram_ldqm,sdram_udqm,sdram_clk,
 inout wire [15:0] sdram_dq);
 wire send,recover,busy,complete,error,backend_reset,mem_valid,mem_done;
 wire [431:0] request_data,mem_data;wire [1279:0] response_data,mem_response;
 wire initialized,delay_ready,parked,axi_idle;
 (* ASYNC_REG="TRUE" *) reg [2:0] park_sync=0;
 always @(posedge aclk)begin
  park_sync<={park_sync[1:0],parked};
  if(!aresetn)begin hold_active<=0;park_sync<=0;end
  else if(!reconfig_hold)hold_active<=0;
  else if(reconfig_safe)hold_active<=1;
 end
 assign reconfig_safe=(!FRONTEND_GUARD || frontend_idle) && axi_idle && park_sync[2] && !link_fault && !hold_active;
 wire reset_request=backend_reset || !locked;
 (* ASYNC_REG="TRUE" *) reg [7:0] reset_pipe=8'hff;
 always @(negedge clk_div or posedge reset_request)
  if(reset_request)reset_pipe<=8'hff;else reset_pipe<={reset_pipe[6:0],!delay_ready};
 s4_shared_axi #(.BASE_ADDR(BASE_ADDR)) axi(.aclk(aclk),.aresetn(aresetn),
  .s_axi_awaddr(s_axi_awaddr),
  .s_axi_awprot(s_axi_awprot),
  .s_axi_awvalid(s_axi_awvalid),
  .s_axi_awready(s_axi_awready),
  .s_axi_wdata(s_axi_wdata),
  .s_axi_wstrb(s_axi_wstrb),
  .s_axi_wvalid(s_axi_wvalid),
  .s_axi_wready(s_axi_wready),
  .s_axi_bresp(s_axi_bresp),
  .s_axi_bvalid(s_axi_bvalid),
  .s_axi_bready(s_axi_bready),
  .s_axi_araddr(s_axi_araddr),
  .s_axi_arprot(s_axi_arprot),
  .s_axi_arvalid(s_axi_arvalid),
  .s_axi_arready(s_axi_arready),
  .s_axi_rdata(s_axi_rdata),
  .s_axi_rresp(s_axi_rresp),
  .s_axi_rvalid(s_axi_rvalid),
  .s_axi_rready(s_axi_rready),
  .link_busy(busy),.link_complete(complete),.link_error(error),.link_fault(link_fault),
  .link_response(response_data),.link_send(send),.link_recover(recover),
  .link_request(request_data),.idle(axi_idle));
 s4_shared_mailbox #(.TIMEOUT_CYCLES(TIMEOUT_CYCLES)) link(.host_clk(aclk),.host_rst(!aresetn),
  .mem_clk(clk_div),.recover(recover),.hold_reset(hold_active),.send(send),.request_data(request_data),
  .busy(busy),.complete(complete),.error(error),.fault(link_fault),.response_data(response_data),
  .backend_reset(backend_reset),.mem_valid(mem_valid),.mem_data(mem_data),
  .mem_done(mem_done),.mem_response(mem_response));
 s4_shared_stack #(.POWER_BEATS(POWER_BEATS)) stack(.clk(clk),.clk_div(clk_div),
  .read_clk(read_clk),.read_clk_div(read_clk_div),.refclk200(refclk200),.rst(reset_pipe[7]),.rst_delay(rst_delay),
  .mem_valid(mem_valid),.mem_data(mem_data),.mem_done(mem_done),.mem_response(mem_response),
  .parked(parked),.initialized(initialized),.delay_ready(delay_ready),
  .sdram_a(sdram_a),.sdram_bs(sdram_bs),.sdram_cke(sdram_cke),.sdram_cs_n(sdram_cs_n),
  .sdram_ras_n(sdram_ras_n),.sdram_cas_n(sdram_cas_n),.sdram_we_n(sdram_we_n),
  .sdram_ldqm(sdram_ldqm),.sdram_udqm(sdram_udqm),.sdram_clk(sdram_clk),.sdram_dq(sdram_dq));
endmodule
