`timescale 1ns/1ps
// AXI4-Lite memory window plus local control page. Instruction reads permitted
// only inside RAM; SmartConnect must split cache refill/writeback AXI bursts.
// No exclusive/atomic or coherence support. One operation at a time;
// AW and W are captured independently. Responses remain stable under backpressure.
module s4_shared_axi #(parameter [31:0] BASE_ADDR=32'h60000000)(
 input wire aclk,aresetn,
 input wire [31:0] s_axi_awaddr,input wire [2:0] s_axi_awprot,
 input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,
 input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp=0,output reg s_axi_bvalid=0,input wire s_axi_bready,
 input wire [31:0] s_axi_araddr,input wire [2:0] s_axi_arprot,
 input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata=0,output reg [1:0] s_axi_rresp=0,
 output reg s_axi_rvalid=0,input wire s_axi_rready,
 input wire link_busy,link_complete,link_error,link_fault,
 input wire [1279:0] link_response,
 output reg link_send=0,link_recover=0,output reg [431:0] link_request=0,
 output wire idle);
 reg aw_pending=0,w_pending=0,ar_pending=0,active=0,active_write=0;
 reg [31:0] aw=0,wd=0,ar=0;reg [3:0] ws=0;
 reg [2:0] awprot=0,arprot=0;
 reg [351:0] cfg=0;reg [1279:0] snapshot=0;
 reg [31:0] sequence_count=0;reg [1:0] last_response=0;
 reg prefer_read=0;
 assign s_axi_awready=aresetn && !aw_pending;
 assign s_axi_wready=aresetn && !w_pending;
 assign s_axi_arready=aresetn && !ar_pending;
 assign idle=!active && !link_send && !link_busy && !aw_pending && !w_pending && !ar_pending && !s_axi_bvalid && !s_axi_rvalid;
 wire select_write=aw_pending && w_pending && !(prefer_read && ar_pending);
 wire [31:0] addr=select_write?aw:ar;
 wire [31:0] offset=addr-BASE_ADDR;
 wire memory_access=addr>=BASE_ADDR && offset<32'h02000000;
 wire control_access=addr>=BASE_ADDR && offset>=32'h02000000 && offset<32'h02001000;
 wire [11:0] regaddr=offset[11:0];
 wire instruction=select_write?awprot[2]:arprot[2];
 reg [31:0] value;reg [1:0] response;reg [3:0] op;
 always @(posedge aclk)begin
  link_send<=0;link_recover<=0;
  if(!aresetn)begin
   aw_pending<=0;w_pending<=0;ar_pending<=0;active<=0;active_write<=0;
   s_axi_bvalid<=0;s_axi_rvalid<=0;s_axi_bresp<=0;s_axi_rresp<=0;s_axi_rdata<=0;
   cfg<=0;snapshot<=0;sequence_count<=0;last_response<=0;prefer_read<=0;link_request<=0;
  end else begin
   if(s_axi_awvalid && s_axi_awready)begin aw<=s_axi_awaddr;awprot<=s_axi_awprot;aw_pending<=1;end
   if(s_axi_wvalid && s_axi_wready)begin wd<=s_axi_wdata;ws<=s_axi_wstrb;w_pending<=1;end
   if(s_axi_arvalid && s_axi_arready)begin ar<=s_axi_araddr;arprot<=s_axi_arprot;ar_pending<=1;end
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(active && link_complete)begin
    active<=0;sequence_count<=sequence_count+1'b1;
    last_response<=link_error?2'b10:link_response[1265:1264];
    if(!link_error)snapshot<=link_response;
    if(active_write)begin s_axi_bvalid<=1;s_axi_bresp<=link_error?2'b10:link_response[1265:1264];end
    else begin
     s_axi_rvalid<=1;s_axi_rresp<=link_error?2'b10:link_response[1265:1264];
     s_axi_rdata<=link_error?0:link_response[1263:1232];
    end
   end
   if(!active && !link_send && !s_axi_bvalid && !s_axi_rvalid && ((aw_pending && w_pending) || ar_pending))begin
    value=0;response=0;op=0;
    prefer_read<=select_write;
    if(select_write)begin aw_pending<=0;w_pending<=0;end else ar_pending<=0;
    if(instruction && (select_write || !memory_access))response=2'b10;
    else if(memory_access)begin
     // Reads return the containing aligned word. Narrow writes use AXI byte lanes.
     if(select_write && |(ws & ((4'b0001<<addr[1:0])-1'b1)))response=2'b10;
     else op=select_write?2:1;
    end else if(!control_access)response=2'b11;
    else if(addr[1:0]!=0)response=2'b10;
    else if(select_write)begin
     if(regaddr>=12'h040 && regaddr<12'h06c)begin
      for(integer b=0;b<4;b++)if(ws[b])cfg[((regaddr-12'h040)>>2)*32+b*8+:8]<=wd[b*8+:8];
     end else if(regaddr==12'h004 && ws==15 && wd>=3 && wd<=7)op=wd[3:0];
     else if(regaddr==12'h018 && ws==15 && wd==1 && !link_busy)link_recover<=1;
     else response=2'b10;
    end else begin
     case(regaddr)
      12'h000:value=32'h53345331; // S4S1
      12'h004:value={30'd0,last_response};
      12'h008:value={28'd0,snapshot[1267:1266],link_fault,link_busy};
      12'h00c:value=sequence_count;
      12'h010:value=32'h02000000;
      12'h014:value=32'h00000001; // exclusive ownership / ABI v1
      default:begin
       if(regaddr>=12'h040 && regaddr<12'h06c)value=cfg[((regaddr-12'h040)>>2)*32+:32];
       else if(regaddr>=12'h100 && regaddr<12'h1a0)value=snapshot[((regaddr-12'h100)>>2)*32+:32];
       else response=2'b11;
      end
     endcase
    end
    if(op!=0)begin
     if(link_fault || link_busy)response=2'b10;
     else begin
      link_request<={8'd0,op,offset,wd,ws,cfg};link_send<=1;active<=1;active_write<=select_write;
     end
    end
    if(op==0 || response!=0)begin
     if(select_write)begin s_axi_bresp<=response;s_axi_bvalid<=1;end
     else begin s_axi_rdata<=value;s_axi_rresp<=response;s_axi_rvalid<=1;end
    end
   end
  end
 end
 initial if(BASE_ADDR[25:0]!=0)$error("BASE_ADDR must be 64 MiB aligned");
endmodule
