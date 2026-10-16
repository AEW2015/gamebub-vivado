`timescale 1ns/1ps
// One transaction at a time; payloads are held until a synchronized acknowledgement.
module sram_phy_mailbox(
 input wire clk,rst_n,mem_clk,io_clk,mem_rst_n,flush,
 input wire req_valid,output wire req_ready,input wire req_write,input wire [17:0] req_addr,input wire [15:0] req_data,input wire [1:0] req_be,input wire [47:0] timings,
 output reg rsp_valid,input wire rsp_ready,output reg [15:0] rsp_data,output wire idle,
 output wire [17:0] sram_a,inout wire [15:0] sram_io,output wire sram_ce_n,sram_oe_n,sram_we_n,sram_ub_n,sram_lb_n);
 reg [84:0] request_payload;reg request_toggle,in_flight;
 reg acknowledge_toggle;reg [15:0] reply_payload;
 (* ASYNC_REG="TRUE" *) reg [1:0] ack_sync;
 (* ASYNC_REG="TRUE" *) reg [1:0] request_sync;
 assign req_ready=!in_flight && !rsp_valid && !flush && rst_n;
 assign idle=!in_flight && !rsp_valid;
 always @(posedge clk)begin
  if(!rst_n || flush)begin request_payload<=0;request_toggle<=0;in_flight<=0;ack_sync<=0;rsp_valid<=0;rsp_data<=0;end
  else begin
   ack_sync<={ack_sync[0],acknowledge_toggle};
   // Preserve all eight bits of every 1.25 ns timing field.
   if(req_valid && req_ready)begin request_payload<={timings,req_be,req_data,req_addr,req_write};request_toggle<=!request_toggle;in_flight<=1;end
   if(in_flight && ack_sync[1]==request_toggle)begin rsp_data<=reply_payload;rsp_valid<=1;in_flight<=0;end
   if(rsp_valid && rsp_ready)rsp_valid<=0;
  end
 end
 reg [84:0] received_payload;reg [1:0] state;reg phy_valid;wire phy_ready,phy_rsp_valid;wire [15:0] phy_rsp_data;
 wire unused_idle;wire [3:0] unused_state;
 always @(posedge mem_clk or negedge mem_rst_n)begin
  if(!mem_rst_n)begin request_sync<=0;acknowledge_toggle<=0;reply_payload<=0;received_payload<=0;state<=0;phy_valid<=0;end
  else begin
   request_sync<={request_sync[0],request_toggle};
   case(state)
    0:if(request_sync[1]!=acknowledge_toggle)begin received_payload<=request_payload;phy_valid<=1;state<=1;end
    1:if(phy_ready)begin phy_valid<=0;state<=2;end
    2:if(phy_rsp_valid)begin reply_payload<=phy_rsp_data;acknowledge_toggle<=request_sync[1];state<=0;end
   endcase
  end
 end
 sram_async_phy phy(.clk(mem_clk),.io_clk(io_clk),.rst_n(mem_rst_n),.req_valid(phy_valid),.req_ready(phy_ready),.req_write(received_payload[0]),.req_addr(received_payload[18:1]),.req_data(received_payload[34:19]),.req_be(received_payload[36:35]),
 .rsp_valid(phy_rsp_valid),.rsp_ready(state==2),.rsp_data(phy_rsp_data),.read_wait(received_payload[44:37]),.write_setup(received_payload[52:45]),.write_width(received_payload[60:53]),.write_hold(received_payload[68:61]),.release_wait(received_payload[76:69]),.address_setup(received_payload[84:77]),
 .idle(unused_idle),.debug_state(unused_state),.sram_a(sram_a),.sram_io(sram_io),.sram_ce_n(sram_ce_n),.sram_oe_n(sram_oe_n),.sram_we_n(sram_we_n),.sram_ub_n(sram_ub_n),.sram_lb_n(sram_lb_n));
endmodule

