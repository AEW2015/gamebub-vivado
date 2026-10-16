`timescale 1ns/1ps
// Dedicated runtime MMCM peripheral. The CPU/debug/LCD/reference clocks must
// NOT use these outputs. Connect reconfig_safe to the memory host's PARK grant.
module serdes4_runtime_clocks #(parameter integer METER_WINDOW=100000)(
 input wire host_clk,rst_n,reconfig_safe,
 output wire clk,clk_div,read_clk,read_clk_div,locked,clock_ready,
 input wire [11:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp=0,output reg s_axi_bvalid=0,input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata=0,output reg [1:0] s_axi_rresp=0,output reg s_axi_rvalid=0,input wire s_axi_rready);
 reg [31:0] cfg[0:5];wire [191:0] staged;
 for(genvar k=0;k<6;k++)assign staged[32*k+:32]=cfg[k];
 reg apply=0;reg [191:0] apply_cfg=0;wire [191:0] active_cfg;
 wire busy,valid,done,rejected,ip_rst_n,meter_enable;wire [7:0] error_code;
 wire [31:0] nominal_hz,measured_cmd,measured_read,epoch,cmd_khz,read_khz;
 wire cmd_valid,read_valid;reg last_rejected=0;reg [31:0] completions=0;
 wire [10:0] awaddr,araddr;wire [31:0] wdata,rdata;wire [3:0] wstrb;
 wire awvalid,awready,wvalid,wready,bvalid,bready,arvalid,arready,rvalid,rready;
 wire [1:0] bresp,rresp;
 assign clock_ready=valid && locked && !busy;
 serdes4_clock_sequencer #(.METER_WINDOW(METER_WINDOW)) sequencer(
  .host_clk(host_clk),.rst(!rst_n),.apply(apply),.reconfig_safe(reconfig_safe),.configuration(apply_cfg),
  .locked(locked),.measured_cmd_khz(cmd_khz),.measured_read_khz(read_khz),.cmd_measure_valid(cmd_valid),.read_measure_valid(read_valid),
  .meter_enable(meter_enable),.ip_aresetn(ip_rst_n),.busy(busy),.clock_valid(valid),.done(done),.rejected(rejected),.error_code(error_code),
  .nominal_hz(nominal_hz),.actual_cmd_khz(measured_cmd),.actual_read_khz(measured_read),.epoch(epoch),.active_configuration(active_cfg),
  .m_axi_awaddr(awaddr),.m_axi_awvalid(awvalid),.m_axi_awready(awready),.m_axi_wdata(wdata),.m_axi_wstrb(wstrb),.m_axi_wvalid(wvalid),.m_axi_wready(wready),
  .m_axi_bresp(bresp),.m_axi_bvalid(bvalid),.m_axi_bready(bready),.m_axi_araddr(araddr),.m_axi_arvalid(arvalid),.m_axi_arready(arready),
  .m_axi_rdata(rdata),.m_axi_rresp(rresp),.m_axi_rvalid(rvalid),.m_axi_rready(rready));
 serdes4_rate_meter #(.WINDOW(METER_WINDOW)) cmd_meter(.measured_clk(clk_div),.host_clk(host_clk),.rst(!rst_n),.enable(meter_enable),.khz(cmd_khz),.valid(cmd_valid));
 serdes4_rate_meter #(.WINDOW(METER_WINDOW)) read_meter(.measured_clk(read_clk_div),.host_clk(host_clk),.rst(!rst_n),.enable(meter_enable),.khz(read_khz),.valid(read_valid));
 serdes4_mmcm_ip clock_ip(.s_axi_aclk(host_clk),.s_axi_aresetn(ip_rst_n),.clk_in1(host_clk),
  .clk_out1(clk),.clk_out2(clk_div),.clk_out3(read_clk),.clk_out4(read_clk_div),.locked(locked),
  .s_axi_awaddr(awaddr),.s_axi_awvalid(awvalid),.s_axi_awready(awready),.s_axi_wdata(wdata),.s_axi_wstrb(wstrb),.s_axi_wvalid(wvalid),.s_axi_wready(wready),
  .s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),.s_axi_araddr(araddr),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
  .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rready));
 reg aw_pending=0,w_pending=0;reg [11:0] aw=0;reg [31:0] wd=0;reg [3:0] ws=0;
 assign s_axi_awready=!aw_pending && !s_axi_bvalid;
 assign s_axi_wready=!w_pending && !s_axi_bvalid;
 assign s_axi_arready=!s_axi_rvalid;
 always @(posedge host_clk)begin
  apply<=0;
  if(!rst_n)begin
   aw_pending<=0;w_pending<=0;s_axi_bvalid<=0;s_axi_rvalid<=0;last_rejected<=0;completions<=0;apply_cfg<=0;
   cfg[0]<=160;cfg[1]<=1;cfg[2]<=5;cfg[3]<=90000;cfg[4]<=22500;cfg[5]<=200000;
  end else begin
   if(done)begin completions<=completions+1'b1;last_rejected<=rejected;end
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_awvalid && s_axi_awready)begin aw<=s_axi_awaddr;aw_pending<=1;end
   if(s_axi_wvalid && s_axi_wready)begin wd<=s_axi_wdata;ws<=s_axi_wstrb;w_pending<=1;end
   if(aw_pending && w_pending && !s_axi_bvalid)begin
    aw_pending<=0;w_pending<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    if(aw>=12'h20 && aw<12'h38 && aw[1:0]==0)begin
     for(integer b=0;b<4;b++)if(ws[b])cfg[(aw-12'h20)>>2][8*b+:8]<=wd[8*b+:8];
    end else if(aw==4 && wd==1 && ws==15 && !busy && reconfig_safe && !apply)begin
     apply<=1;apply_cfg<=staged;last_rejected<=0;
    end else s_axi_bresp<=2;
   end
   if(s_axi_arvalid && s_axi_arready)begin
    s_axi_rvalid<=1;s_axi_rresp<=0;s_axi_rdata<=0;
    case(s_axi_araddr)
     0:s_axi_rdata<=32'h53344331; // S4C1
     4:s_axi_rdata<={16'd0,error_code,3'd0,reconfig_safe,last_rejected,locked,clock_ready,busy};
     8:s_axi_rdata<=completions;
     12:s_axi_rdata<=epoch;
     'h40:s_axi_rdata<=nominal_hz;
     'h44:s_axi_rdata<=measured_cmd;
     'h48:s_axi_rdata<=measured_read;
     default:begin
      if(s_axi_araddr>='h20 && s_axi_araddr<'h38 && s_axi_araddr[1:0]==0)s_axi_rdata<=cfg[(s_axi_araddr-'h20)>>2];
      else if(s_axi_araddr>='h60 && s_axi_araddr<'h78 && s_axi_araddr[1:0]==0)s_axi_rdata<=active_cfg[((s_axi_araddr-'h60)>>2)*32+:32];
      else s_axi_rresp<=2;
     end
    endcase
   end
  end
 end
endmodule
