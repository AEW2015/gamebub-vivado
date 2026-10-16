`timescale 1ns/1ps
// Fixed 100 MHz CPU input; owns its own 100/400 MHz SRAM MMCM.
module sram_shared_memory(
 input wire clk,rst_n,
 input wire [47:0] normal_timings,
 input wire test_request,output wire test_grant,switching,healthy,clock_fault,
 input wire t_valid,output wire t_ready,input wire t_write,input wire [17:0] t_addr,input wire [15:0] t_data,input wire [1:0] t_be,input wire [47:0] t_timings,
 output wire t_rsp_valid,input wire t_rsp_ready,output wire [15:0] t_rsp_data,output wire t_rsp_error,
 input wire [31:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output wire s_axi_bvalid,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output wire s_axi_rvalid,input wire s_axi_rready,
 output wire [17:0] sram_a,inout wire [15:0] sram_io,output wire sram_ce_n,sram_oe_n,sram_we_n,sram_ub_n,sram_lb_n
);
 wire mem_clk,io_clk,mem_rst_n,clock_ready,clock_busy;wire [2:0] selected;
 wire phy_ready=healthy;wire phy_idle;
 wire p_valid,p_ready,p_write,p_rsp_valid,p_rsp_ready;wire [17:0] p_addr;
 wire [15:0] p_data,p_rsp_data;wire [1:0] p_be;wire [47:0] p_timings;
 assign healthy=clock_ready && !clock_fault;
 sram_clock_tree clocks(.clk(clk),.rst_n(rst_n),.request(1'b0),.profile(3'd0),
 .mem_clk(mem_clk),.io_clk(io_clk),.mem_rst_n(mem_rst_n),.ready(clock_ready),.busy(clock_busy),.fault(clock_fault),.selected(selected));
 sram_shared_core core(.*);
 sram_phy_mailbox mailbox(.clk(clk),.rst_n(rst_n),.mem_clk(mem_clk),.io_clk(io_clk),.mem_rst_n(mem_rst_n),.flush(!healthy),
 .req_valid(p_valid),.req_ready(p_ready),.req_write(p_write),.req_addr(p_addr),.req_data(p_data),.req_be(p_be),.timings(p_timings),
 .rsp_valid(p_rsp_valid),.rsp_ready(p_rsp_ready),.rsp_data(p_rsp_data),.idle(phy_idle),
 .sram_a(sram_a),.sram_io(sram_io),.sram_ce_n(sram_ce_n),.sram_oe_n(sram_oe_n),.sram_we_n(sram_we_n),.sram_ub_n(sram_ub_n),.sram_lb_n(sram_lb_n));
endmodule
