`timescale 1ns/1ps
module sram_shared_peripheral #(parameter integer DEFAULT_TEST_WORDS=4096)(
 input wire clk,rst_n,output wire healthy,clock_fault,test_grant,switching,
 input wire [31:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output wire s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output wire s_axi_rvalid,input wire s_axi_rready,
 input wire [11:0] s_ctrl_awaddr,input wire s_ctrl_awvalid,output wire s_ctrl_awready,
 input wire [31:0] s_ctrl_wdata,input wire [3:0] s_ctrl_wstrb,input wire s_ctrl_wvalid,output wire s_ctrl_wready,
 output wire [1:0] s_ctrl_bresp,output wire s_ctrl_bvalid,input wire s_ctrl_bready,
 input wire [11:0] s_ctrl_araddr,input wire s_ctrl_arvalid,output wire s_ctrl_arready,
 output wire [31:0] s_ctrl_rdata,output wire [1:0] s_ctrl_rresp,output wire s_ctrl_rvalid,input wire s_ctrl_rready,
 output wire [17:0] sram_a,inout wire [15:0] sram_io,output wire sram_ce_n,sram_oe_n,sram_we_n,sram_ub_n,sram_lb_n
);
 wire [47:0] normal_timings;
 wire test_request,t_valid,t_ready,t_write,t_rsp_valid,t_rsp_ready,t_rsp_error;
 wire [17:0] t_addr;wire [15:0] t_data,t_rsp_data;wire [1:0] t_be;wire [47:0] t_timings;
 sram_shared_memory memory(.*);
 sram_shared_tester #(.CLOCK_HZ(100000000),.DEFAULT_TEST_WORDS(DEFAULT_TEST_WORDS)) tester(.clk(clk),.rst_n(rst_n),.clock_ready(healthy),.clock_fault(clock_fault),.test_request(test_request),.test_grant(test_grant),.timings(t_timings),.normal_timings(normal_timings),
 .req_valid(t_valid),.req_ready(t_ready),.req_write(t_write),.req_addr(t_addr),.req_data(t_data),.req_be(t_be),
 .rsp_valid(t_rsp_valid),.rsp_ready(t_rsp_ready),.rsp_data(t_rsp_data),.rsp_error(t_rsp_error),
 .s_axi_awaddr(s_ctrl_awaddr),
 .s_axi_awvalid(s_ctrl_awvalid),
 .s_axi_awready(s_ctrl_awready),
 .s_axi_wdata(s_ctrl_wdata),
 .s_axi_wstrb(s_ctrl_wstrb),
 .s_axi_wvalid(s_ctrl_wvalid),
 .s_axi_wready(s_ctrl_wready),
 .s_axi_bresp(s_ctrl_bresp),
 .s_axi_bvalid(s_ctrl_bvalid),
 .s_axi_bready(s_ctrl_bready),
 .s_axi_araddr(s_ctrl_araddr),
 .s_axi_arvalid(s_ctrl_arvalid),
 .s_axi_arready(s_ctrl_arready),
 .s_axi_rdata(s_ctrl_rdata),
 .s_axi_rresp(s_ctrl_rresp),
 .s_axi_rvalid(s_ctrl_rvalid),
 .s_axi_rready(s_ctrl_rready));
endmodule
