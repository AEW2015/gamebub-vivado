`timescale 1ns/1ps
// One four-phase bundled-data transaction. Payloads stay frozen until RTZ.
// Host watchdog quarantines AND resets the backend; late replies cannot be reused.
module s4_shared_mailbox #(parameter integer TIMEOUT_CYCLES=65536)(
 input wire host_clk,host_rst,mem_clk,recover,hold_reset,
 input wire send,input wire [431:0] request_data,
 output wire busy,output reg complete=0,error=0,fault=0,
 output reg [1279:0] response_data=0,
 output wire backend_reset,
 output reg mem_valid=0,output reg [431:0] mem_data=0,
 input wire mem_done,input wire [1279:0] mem_response);
 localparam integer CW=$clog2(TIMEOUT_CYCLES+1);
 reg [CW-1:0] timer=0;
 reg [4:0] reset_count=16;
 reg request=0,ack=0,waiting=0,returning=0;
 reg [431:0] held_request=0;
 reg [1279:0] held_response=0;
 (* ASYNC_REG="TRUE" *) reg [2:0] ack_sync=0,req_sync=0;
 (* ASYNC_REG="TRUE" *) reg [2:0] mem_reset_pipe=7;
 wire reset_link=host_rst || hold_reset || fault || (reset_count!=0);
 assign backend_reset=mem_reset_pipe[2];
 assign busy=waiting || returning || hold_reset || (reset_count!=0);
 always @(negedge mem_clk or posedge reset_link)
  if(reset_link)mem_reset_pipe<=7;else mem_reset_pipe<={mem_reset_pipe[1:0],1'b0};
 always @(posedge host_clk)begin
  complete<=0;ack_sync<={ack_sync[1:0],ack};
  if(host_rst)begin
   request<=0;waiting<=0;returning<=0;timer<=0;fault<=0;error<=0;
   reset_count<=16;ack_sync<=0;response_data<=0;held_request<=0;
  end else if(hold_reset)begin
   request<=0;waiting<=0;returning<=0;timer<=0;ack_sync<=0;reset_count<=16;
  end else if(recover && !waiting && !returning)begin
   request<=0;fault<=0;error<=0;reset_count<=16;ack_sync<=0;
  end else if(reset_count!=0)begin reset_count<=reset_count-1'b1;ack_sync<=0;end
  else if(!fault)begin
   if(send && !busy)begin held_request<=request_data;request<=1;waiting<=1;timer<=0;error<=0;end
   if(waiting || returning)begin
    if(timer==TIMEOUT_CYCLES-1)begin
     fault<=1;error<=1;complete<=1;request<=0;waiting<=0;returning<=0;
    end else begin
     timer<=timer+1'b1;
     if(waiting && ack_sync[2])begin
      response_data<=held_response;request<=0;waiting<=0;returning<=1;
     end
     if(returning && !ack_sync[2])begin returning<=0;complete<=1;end
    end
   end
  end
 end
 reg [1:0] state=0;
 always @(posedge mem_clk or posedge backend_reset)begin
  if(backend_reset)begin req_sync<=0;ack<=0;mem_valid<=0;mem_data<=0;held_response<=0;state<=0;end
  else begin
   req_sync<={req_sync[1:0],request};
   case(state)
    0:if(req_sync[2])state<=1;
    1:begin mem_data<=held_request;mem_valid<=1;state<=2;end
    2:if(mem_done)begin held_response<=mem_response;mem_valid<=0;ack<=1;state<=3;end
    3:if(!req_sync[2])begin ack<=0;state<=0;end
   endcase
  end
 end
 initial if(TIMEOUT_CYCLES<16)$error("Timeout must be at least 16 host cycles");
endmodule
