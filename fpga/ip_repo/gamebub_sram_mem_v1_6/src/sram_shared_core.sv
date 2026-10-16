`timescale 1ns/1ps
module sram_shared_core(
 input wire clk,rst_n,phy_ready,phy_idle,
 input wire [47:0] normal_timings,
 input wire test_request,output wire test_grant,switching,
 input wire t_valid,output wire t_ready,input wire t_write,input wire [17:0] t_addr,input wire [15:0] t_data,input wire [1:0] t_be,input wire [47:0] t_timings,
 output wire t_rsp_valid,input wire t_rsp_ready,output wire [15:0] t_rsp_data,output wire t_rsp_error,
 input wire [31:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output wire s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output wire s_axi_rvalid,input wire s_axi_rready,
 output wire p_valid,input wire p_ready,output wire p_write,output wire [17:0] p_addr,output wire [15:0] p_data,output wire [1:0] p_be,output wire [47:0] p_timings,
 input wire p_rsp_valid,output wire p_rsp_ready,input wire [15:0] p_rsp_data
);
 wire cpu_idle,c_valid,c_ready,c_write,c_rsp_valid,c_rsp_ready,c_rsp_error;
 wire [17:0] c_addr;wire [15:0] c_data,c_rsp_data;wire [1:0] c_be;
 sram_cpu_axi cpu(.clk(clk),.rst_n(rst_n),.enabled(!test_request && !test_grant && phy_ready),
 .s_axi_awaddr(s_axi_awaddr),
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
 .s_axi_arvalid(s_axi_arvalid),
 .s_axi_arready(s_axi_arready),
 .s_axi_rdata(s_axi_rdata),
 .s_axi_rresp(s_axi_rresp),
 .s_axi_rvalid(s_axi_rvalid),
 .s_axi_rready(s_axi_rready),
 .idle(cpu_idle),.req_valid(c_valid),.req_ready(c_ready),.req_write(c_write),.req_addr(c_addr),.req_data(c_data),.req_be(c_be),
 .rsp_valid(c_rsp_valid),.rsp_ready(c_rsp_ready),.rsp_data(c_rsp_data),.rsp_error(c_rsp_error));
 sram_shared_arbiter arbiter(.*);
endmodule
