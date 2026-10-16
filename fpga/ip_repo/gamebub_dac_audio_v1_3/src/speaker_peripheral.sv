`timescale 1ns/1ps
module speaker_peripheral #(parameter CLOCK_HZ=29361979,DEFAULT_FREQUENCY=440,DEFAULT_LEVEL=10,DEFAULT_LIMIT_MS=5000)(
 input wire clk,rst_n,stop_n,output wire dac_bclk,dac_wclk,dac_din,
 input wire [11:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata,output reg [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready);
 reg [31:0] cfg[0:4];reg [11:0] aw;reg [31:0] wd;reg [3:0] ws;
 reg have_aw,have_w,start,stop,heartbeat;
 wire running;wire [2:0] reason;wire [31:0] remaining_ms,frames;
 wire valid_cfg=cfg[0]>=20 && cfg[0]<=12000 && cfg[1]<=100 && cfg[2]<=2 && cfg[3]<=2 && cfg[4]>=100 && cfg[4]<=30000;
 assign s_axi_awready=rst_n && !have_aw && !s_axi_bvalid;
 assign s_axi_wready=rst_n && !have_w && !s_axi_bvalid;
 assign s_axi_arready=rst_n && !s_axi_rvalid;
 speaker_engine #(.CLOCK_HZ(CLOCK_HZ)) engine(
 .clk(clk),.rst_n(rst_n),.stop_n(stop_n),.start(start),.stop(stop),.heartbeat(heartbeat),
 .frequency(cfg[0]),.level(cfg[1]),.waveform(cfg[2]),.channels(cfg[3]),.limit_ms(cfg[4]),
 .running(running),.reason(reason),.remaining_ms(remaining_ms),.frames(frames),.dac_bclk(dac_bclk),.dac_wclk(dac_wclk),.dac_din(dac_din));
 integer i;
 always @(posedge clk)begin
  if(!rst_n)begin
   have_aw<=0;have_w<=0;aw<=0;wd<=0;ws<=0;s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rresp<=0;s_axi_rdata<=0;
   start<=0;stop<=0;heartbeat<=0;cfg[0]<=DEFAULT_FREQUENCY;cfg[1]<=DEFAULT_LEVEL;cfg[2]<=0;cfg[3]<=0;cfg[4]<=DEFAULT_LIMIT_MS;
  end else begin
   start<=0;stop<=0;heartbeat<=0;
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_awvalid && s_axi_awready)begin aw<=s_axi_awaddr;have_aw<=1;end
   if(s_axi_wvalid && s_axi_wready)begin wd<=s_axi_wdata;ws<=s_axi_wstrb;have_w<=1;end
   if(have_aw && have_w && !s_axi_bvalid)begin
    have_aw<=0;have_w<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    if(aw>=12'h020 && aw<=12'h030 && aw[1:0]==0 && !running && !start)begin
     for(i=0;i<4;i=i+1)if(ws[i])cfg[(aw-12'h020)>>2][i*8+:8]<=wd[i*8+:8];
    end else if(aw==4 && ws==15)begin
     if(wd==2)stop<=1;
     else if(wd==1 && valid_cfg && !running && !start)start<=1;
     else s_axi_bresp<=2;
    end else if(aw==12'h010 && ws==15 && wd==32'h53504b31)heartbeat<=1;
    else s_axi_bresp<=2;
   end
   if(s_axi_arvalid && s_axi_arready)begin
    s_axi_rvalid<=1;s_axi_rresp<=0;s_axi_rdata<=0;
    case(s_axi_araddr)
     0:s_axi_rdata<=32'h53504b01;
     4:s_axi_rdata<=0;
     8:s_axi_rdata<={25'd0,reason,3'd0,running};
     12:s_axi_rdata<=remaining_ms;
     16:s_axi_rdata<=frames;
     20:s_axi_rdata<=48293;
     24:s_axi_rdata<=CLOCK_HZ;
     default:if(s_axi_araddr>=12'h020 && s_axi_araddr<=12'h030 && s_axi_araddr[1:0]==0)s_axi_rdata<=cfg[(s_axi_araddr-12'h020)>>2];else s_axi_rresp<=2;
    endcase
   end
  end
 end
endmodule



