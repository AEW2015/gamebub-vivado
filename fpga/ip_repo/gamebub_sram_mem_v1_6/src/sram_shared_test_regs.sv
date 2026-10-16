// Derived from frozen vendor/sram_test_regs.sv; distinct shared-tester ID.
module sram_shared_test_regs #(parameter integer DEFAULT_TEST_WORDS=4096)(
 input wire clk,rst_n,
 input wire [11:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata,output reg [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready,
 input wire [2047:0] status,input wire [255:0] active,input wire armed,applying,quiescent,fault,
 output reg [6:0] command,output reg [255:0] requested);
 reg [31:0] shadow[0:7];reg [2047:0] snapshot;
 reg [31:0] snapshot_seq;
 reg [11:0] aw;reg [31:0] wd;reg [3:0] ws;reg have_aw,have_w;
 integer i,j;
 wire [19:0] range_end={2'd0,shadow[0][17:0]}+{1'b0,shadow[1][18:0]};
 wire valid_cfg=(shadow[0]<262144 && shadow[1]>=1 && shadow[1]<=262144 && range_end<=262144 &&
  shadow[2][3:0]<=8 && shadow[2][6:4]<=4 && shadow[2][15:10]==0 && !shadow[2][7] &&
  shadow[3][7:0]<=255 && shadow[3][15:8]<=255 &&
  shadow[3][23:16]<=255 && shadow[3][31:24]<=255 &&
  shadow[4][7:0]<=255 && shadow[4][15:8]<=255 &&
  shadow[4][31:16]==0 && shadow[5]<=60000 && shadow[6]==0);
 assign s_axi_awready=!have_aw && !s_axi_bvalid;
 assign s_axi_wready=!have_w && !s_axi_bvalid;
 assign s_axi_arready=!s_axi_rvalid;
 always @(posedge clk)begin
  if(!rst_n)begin
   have_aw<=0;have_w<=0;aw<=0;wd<=0;ws<=0;s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rresp<=0;s_axi_rdata<=0;
   command<=0;requested<=0;snapshot<=0;snapshot_seq<=0;
   shadow[0]<=0;shadow[1]<=DEFAULT_TEST_WORDS;shadow[2]<=32'h1d0f0008;shadow[3]<=32'h20202040;shadow[4]<=32'h00002020;shadow[5]<=0;shadow[6]<=0;shadow[7]<=0;
  end else begin
   command<=0;
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_awvalid && s_axi_awready)begin aw<=s_axi_awaddr;have_aw<=1;end
   if(s_axi_wvalid && s_axi_wready)begin wd<=s_axi_wdata;ws<=s_axi_wstrb;have_w<=1;end
   if(have_aw && have_w && !s_axi_bvalid)begin
    have_aw<=0;have_w<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    if(aw>=12'h020 && aw<12'h040 && aw[1:0]==0)begin
     for(j=0;j<4;j=j+1)if(ws[j])shadow[aw[4:2]][j*8+:8]<=wd[j*8+:8];
    end else if(aw==4 && ws==15)begin
     // Commands are one-hot W1 pulses. Busy/invalid requests are explicitly rejected.
     if(wd==0 || wd>64 || (wd&(wd-1))!=0 ||
       (status[51*32+1] && !wd[4]) ||
       ((wd[5] || wd[6]) && (armed || applying || !quiescent || !status[48*32+2])) ||
       (wd[5] && (!status[51*32] || fault)) ||
       (wd[2] && (!valid_cfg || applying)) ||
       (wd[0] && (fault || armed || applying || !quiescent)) || (wd[3] && (armed || applying || !quiescent)))s_axi_bresp<=2;
     else begin
      command<=wd[6:0];
      if(wd[2])for(i=0;i<8;i=i+1)requested[i*32+:32]<=shadow[i];
      if(wd[4])begin snapshot<=status;snapshot_seq<=snapshot_seq+1'b1;end
     end
    end else s_axi_bresp<=2;
   end
   if(s_axi_arvalid && s_axi_arready)begin
    s_axi_rvalid<=1;s_axi_rresp<=0;s_axi_rdata<=0;
    case(s_axi_araddr)
     0:s_axi_rdata<=32'h53524802;
     4:s_axi_rdata<=0;
     8:s_axi_rdata<={28'd0,fault,applying,!quiescent,armed};
     12:s_axi_rdata<=snapshot_seq;
     16:s_axi_rdata<=32'h0003011f; // ABI 1, fixed PHY clocks, modes 0..4
     20:s_axi_rdata<=262144;
     24:s_axi_rdata<=status[48*32+:32];
     28:s_axi_rdata<=status[51*32+:32];
     96:s_axi_rdata<=status[49*32+:32];
     100:s_axi_rdata<=status[50*32+:32];
     default:begin
      if(s_axi_araddr[1:0]!=0)s_axi_rresp<=2;
      else if(s_axi_araddr>=12'h020 && s_axi_araddr<12'h040)s_axi_rdata<=shadow[s_axi_araddr[4:2]];
      else if(s_axi_araddr>=12'h040 && s_axi_araddr<12'h060)s_axi_rdata<=active[s_axi_araddr[4:2]*32+:32];
      else if(s_axi_araddr>=12'h100 && s_axi_araddr<12'h200)s_axi_rdata<=snapshot[s_axi_araddr[7:2]*32+:32];
      else s_axi_rresp<=2;
     end
    endcase
   end
  end
 end
endmodule

