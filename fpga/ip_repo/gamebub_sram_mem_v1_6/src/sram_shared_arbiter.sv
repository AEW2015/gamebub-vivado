`timescale 1ns/1ps
// CPU-domain ownership and response tracking. Never switch halfway through
// a CPU 32-bit operation or an unconsumed tester response.
module sram_shared_arbiter(
 input wire clk,rst_n,phy_ready,phy_idle,
 input wire [47:0] normal_timings,
 input wire test_request,input wire cpu_idle,output reg test_grant,output wire switching,
 input wire c_valid,output wire c_ready,input wire c_write,input wire [17:0] c_addr,input wire [15:0] c_data,input wire [1:0] c_be,
 output wire c_rsp_valid,input wire c_rsp_ready,output wire [15:0] c_rsp_data,output wire c_rsp_error,
 input wire t_valid,output wire t_ready,input wire t_write,input wire [17:0] t_addr,input wire [15:0] t_data,input wire [1:0] t_be,input wire [47:0] t_timings,
 output wire t_rsp_valid,input wire t_rsp_ready,output wire [15:0] t_rsp_data,output wire t_rsp_error,
 output wire p_valid,input wire p_ready,output wire p_write,output wire [17:0] p_addr,output wire [15:0] p_data,output wire [1:0] p_be,output wire [47:0] p_timings,
 input wire p_rsp_valid,output wire p_rsp_ready,input wire [15:0] p_rsp_data);
 reg pending,reply_valid,reply_error,reply_owner;reg [15:0] reply_data;
 wire available=!pending && !reply_valid;
 wire selected_valid=test_grant?(test_request && t_valid):c_valid;
 // A CPU transaction accepted before takeover is allowed to finish both halves.
 assign p_valid=available && selected_valid && phy_ready;
 assign p_write=test_grant?t_write:c_write;
 assign p_addr=test_grant?t_addr:c_addr;
 assign p_data=test_grant?t_data:c_data;
 assign p_be=test_grant?t_be:c_be;
 assign p_timings=test_grant?t_timings:normal_timings;
 // When the clock fails, accept locally and return an error, without pin work.
 assign c_ready=available && !test_grant && (!phy_ready || p_ready);
 assign t_ready=available && test_grant && test_request && (!phy_ready || p_ready);
 assign p_rsp_ready=pending;
 assign c_rsp_valid=reply_valid && !reply_owner;
 assign t_rsp_valid=reply_valid && reply_owner;
 assign c_rsp_data=reply_data;assign t_rsp_data=reply_data;
 assign c_rsp_error=c_rsp_valid && reply_error;assign t_rsp_error=t_rsp_valid && reply_error;
 assign switching=test_request!=test_grant;
 always @(posedge clk)begin
  if(!rst_n)begin test_grant<=0;pending<=0;reply_valid<=0;reply_error<=0;reply_owner<=0;reply_data<=0;end
  else begin
   if(available && cpu_idle && phy_idle && !selected_valid)test_grant<=test_request;
   if((c_valid && c_ready) || (t_valid && t_ready))begin
    reply_owner<=test_grant;reply_error<=0;
    if(phy_ready)pending<=1;
    else begin reply_valid<=1;reply_error<=1;reply_data<=0;end
   end
   if(pending && (!phy_ready || p_rsp_valid))begin
    pending<=0;reply_valid<=1;reply_error<=!phy_ready;reply_data<=phy_ready?p_rsp_data:16'd0;
   end
   if(reply_valid && (reply_owner?t_rsp_ready:c_rsp_ready))reply_valid<=0;
  end
 end
endmodule
