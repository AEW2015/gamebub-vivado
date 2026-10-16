`timescale 1ns/1ps
// Conservative closed-page controller, one fully reserved BL4/BL8 request.
// Timing counts deliberately cover the fixed 166..250 MHz development range:
// minimum waits use 250 MHz, refresh spacing uses 166 MHz. Not runtime DRP.
// Word address: bank[23:22], row[21:9], column[8:0]; requests must be BL aligned.
module serdes4_controller #(parameter integer BURST_WORDS=8,POWER_BEATS=15625)(
 input wire clk_div,rst,
 input wire req_valid,output wire req_ready,input wire req_write,
 input wire [23:0] req_addr,input wire [127:0] req_data,input wire [15:0] req_mask,
 output reg rsp_valid=0,input wire rsp_ready,output reg [127:0] rsp_data=0,
 output reg [2:0] rsp_status=0,output reg initialized=0,output reg fatal=0,
 output reg [31:0] refresh_count=0,
 output reg [95:0] tx_ca,output reg [63:0] tx_data=0,output reg tx_drive=0,
 output reg read_issue=0,input wire read_valid,output wire read_ready,
 input wire [127:0] read_data,input wire read_fault,
 output wire read_fault_synced);
 localparam [23:0] NOP={2'b11,2'b10,3'b111,2'b00,13'd0,2'b00};
 localparam [23:0] POWER_NOP={2'b00,2'b11,3'b111,2'b00,13'd0,2'b00};
 localparam integer RP=4,RCD=4,RFC=6;
 typedef enum logic [4:0] {POWER,WAKE,INIT_PRE,INIT_RP,INIT_REF,INIT_RFC,MODE,MODE_WAIT,
  IDLE,ACT,RCD_WAIT,WRITE_GUARD,WRITE_FIRST,WRITE_SECOND,WRITE_HOLD,
  RELEASE_DQ,READ_CMD,READ_WAIT,PRE,PRE_WAIT,COMPLETE,REF_WAIT} state_t;
 state_t state=POWER;
 reg [15:0] wait_count=0;reg [9:0] refresh_age=0;reg [3:0] init_refs=0;
 reg [23:0] address=0;reg writing=0;reg [127:0] write_data=0;
 reg [15:0] mask=0;
 (* ASYNC_REG="TRUE" *) reg fault_meta=0,fault_sync=0;
 assign read_fault_synced=fault_sync;
 function automatic [23:0] ca(input [2:0] cmd,input [1:0] bank,input [12:0] a,input [1:0] m);
  ca={2'b11,2'b10,cmd,bank,a,m};
 endfunction
 assign req_ready=initialized && state==IDLE && !rsp_valid && !fatal && refresh_age<128;
 assign read_ready=state==READ_WAIT;
 initial begin
  tx_ca={4{POWER_NOP}};
  if(BURST_WORDS!=4 && BURST_WORDS!=8)$error("BURST_WORDS must be 4 or 8");
  if(POWER_BEATS<1 || POWER_BEATS>65535)$error("POWER_BEATS out of counter range");
 end
 always @(posedge clk_div)begin
  if(rst)begin
   state<=POWER;wait_count<=0;refresh_age<=0;init_refs<=0;initialized<=0;
   fatal<=0;refresh_count<=0;tx_ca<={4{POWER_NOP}};tx_data<=0;tx_drive<=0;
   read_issue<=0;rsp_valid<=0;rsp_data<=0;rsp_status<=0;
   address<=0;writing<=0;write_data<=0;mask<=0;fault_meta<=0;fault_sync<=0;
  end else begin
   fault_meta<=read_fault;fault_sync<=fault_meta;
   tx_ca<={4{NOP}};read_issue<=0;
   if(rsp_valid && rsp_ready)rsp_valid<=0;
   if(initialized)begin
    if(refresh_age<1023)refresh_age<=refresh_age+1'b1;
    if(refresh_age>=320 || fault_sync)fatal<=1;
   end
   if(wait_count!=0)wait_count<=wait_count-1'b1;
   case(state)
    POWER:begin
     tx_ca<={4{POWER_NOP}};
     if(wait_count==POWER_BEATS-1)begin wait_count<=4;state<=WAKE;end
     else wait_count<=wait_count+1'b1;
    end
    WAKE:if(wait_count==0)state<=INIT_PRE;
    INIT_PRE:begin tx_ca[23:0]<=ca(2,0,13'h400,0);wait_count<=RP;state<=INIT_RP;end
    INIT_RP:if(wait_count==0)state<=INIT_REF;
    INIT_REF:begin
     tx_ca[23:0]<=ca(1,0,0,0);init_refs<=init_refs+1'b1;
     wait_count<=RFC;state<=INIT_RFC;
    end
    INIT_RFC:if(wait_count==0)begin if(init_refs==8)state<=MODE;else state<=INIT_REF;end
    MODE:begin tx_ca[23:0]<=ca(0,0,BURST_WORDS==8?13'h033:13'h032,0);wait_count<=4;state<=MODE_WAIT;end
    MODE_WAIT:if(wait_count==0)begin initialized<=1;refresh_age<=0;state<=IDLE;end
    IDLE:begin
     tx_drive<=0;
     if(refresh_age>=128)begin
      tx_ca[23:0]<=ca(1,0,0,0);refresh_age<=0;refresh_count<=refresh_count+1'b1;
      wait_count<=RFC;state<=REF_WAIT;
     end else if(req_valid && req_ready)begin
      address<=req_addr;writing<=req_write;write_data<=req_data;mask<=req_mask;
      rsp_data<=0;rsp_status<=0;
      if((req_addr & (BURST_WORDS-1))!=0)begin rsp_status<=1;rsp_valid<=1;end
      else state<=ACT;
     end
    end
    ACT:begin tx_ca[23:0]<=ca(3,address[23:22],address[21:9],0);wait_count<=RCD;state<=RCD_WAIT;end
    RCD_WAIT:if(wait_count==0)begin
     if(writing)begin tx_drive<=1;wait_count<=2;state<=WRITE_GUARD;end
     else state<=READ_CMD;
    end
    WRITE_GUARD:if(wait_count==0)state<=WRITE_FIRST;
    WRITE_FIRST:begin
     for(integer j=0;j<4;j=j+1)
      tx_ca[24*j+:24]<=ca(j==0?3'd4:3'd7,address[23:22],{4'd0,address[8:0]},mask[2*j+:2]);
     tx_data<=write_data[63:0];
     if(BURST_WORDS==8)state<=WRITE_SECOND;
     else begin wait_count<=3;state<=WRITE_HOLD;end
    end
    WRITE_SECOND:begin
     for(integer j=0;j<4;j=j+1)tx_ca[24*j+:24]<=ca(7,0,0,mask[8+2*j+:2]);
     tx_data<=write_data[127:64];wait_count<=3;state<=WRITE_HOLD;
    end
    WRITE_HOLD:if(wait_count==0)begin tx_drive<=0;wait_count<=3;state<=RELEASE_DQ;end
    RELEASE_DQ:if(wait_count==0)state<=PRE;
    READ_CMD:begin
     tx_ca[23:0]<=ca(5,address[23:22],{4'd0,address[8:0]},0);
     read_issue<=1;wait_count<=64;state<=READ_WAIT;
    end
    READ_WAIT:begin
     if(read_valid)begin
      rsp_data<=BURST_WORDS==8?read_data:{64'd0,read_data[63:0]};
      if(fault_sync)begin rsp_status<=3;fatal<=1;end
      state<=PRE;
     end else if(wait_count==0)begin rsp_status<=2;fatal<=1;state<=PRE;end
    end
    PRE:begin tx_ca[23:0]<=ca(2,address[23:22],0,0);wait_count<=RP;state<=PRE_WAIT;end
    PRE_WAIT:if(wait_count==0)state<=COMPLETE;
    COMPLETE:begin rsp_valid<=1;state<=IDLE;end
    REF_WAIT:if(wait_count==0)state<=IDLE;
    default:begin fatal<=1;state<=POWER;end
   endcase
  end
 end
endmodule
