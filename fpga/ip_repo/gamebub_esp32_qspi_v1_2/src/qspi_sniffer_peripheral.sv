`timescale 1ns/1ps
module qspi_sniffer_peripheral(
 input wire clk,rst_n,rx_clk,rx_locked,qspi_sck,qspi_cs_n,input wire [3:0] qspi_dq,
 input wire [11:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output reg [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output reg [31:0] s_axi_rdata,output reg [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready);
 reg enabled=0,pop=0,have_aw=0,have_w=0;
 reg [11:0] aw;reg [31:0] wd;reg [3:0] ws;
 (* ASYNC_REG="TRUE" *) reg [2:0] rx_reset=0;
 always @(posedge rx_clk or negedge rx_locked)if(!rx_locked)rx_reset<=0;else rx_reset<={rx_reset[1:0],1'b1};
 wire valid;wire [191:0] record,head;wire empty,full,wr_busy,rd_busy;wire [6:0] level;
 qspi_sniffer_capture capture(.clk(rx_clk),.rst_n(rx_reset[2]),.enable(enabled),
 .qspi_sck(qspi_sck),.qspi_cs_n(qspi_cs_n),.qspi_dq(qspi_dq),.valid(valid),.record(record));
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("block"),.FIFO_WRITE_DEPTH(64),.WRITE_DATA_WIDTH(192),
 .READ_DATA_WIDTH(192),.READ_MODE("fwft"),.FIFO_READ_LATENCY(0),.CDC_SYNC_STAGES(2),
 .RD_DATA_COUNT_WIDTH(7),.WR_DATA_COUNT_WIDTH(7),.PROG_EMPTY_THRESH(10),.PROG_FULL_THRESH(54),
 .USE_ADV_FEATURES("0707"),.SIM_ASSERT_CHK(1)) records(
 .rst(!rx_locked),.wr_clk(rx_clk),.wr_en(rx_reset[2]&&valid&&!full&&!wr_busy),.din(record),.full(full),.wr_rst_busy(wr_busy),
 .rd_clk(clk),.rd_en(pop&&!empty&&!rd_busy),.dout(head),.empty(empty),.rd_rst_busy(rd_busy),.rd_data_count(level),
 .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
 reg [31:0] totals=0,drops=0,malformed=0;
 always @(posedge rx_clk)begin
  if(!rx_reset[2])begin totals<=0;drops<=0;malformed<=0;end
  else if(valid)begin
   totals<=totals+1'b1;
   if(full||wr_busy)drops<=drops+1'b1;
   if(record[23:16]!=0)malformed<=malformed+1'b1;
  end
 end
 wire [31:0] total_host,drop_host,bad_host;
 xpm_cdc_gray #(.WIDTH(32),.DEST_SYNC_FF(2),.SIM_ASSERT_CHK(1),.SIM_LOSSLESS_GRAY_CHK(0)) total_cdc(.src_clk(rx_clk),.src_in_bin(totals),.dest_clk(clk),.dest_out_bin(total_host));
 xpm_cdc_gray #(.WIDTH(32),.DEST_SYNC_FF(2),.SIM_ASSERT_CHK(1),.SIM_LOSSLESS_GRAY_CHK(0)) drop_cdc(.src_clk(rx_clk),.src_in_bin(drops),.dest_clk(clk),.dest_out_bin(drop_host));
 xpm_cdc_gray #(.WIDTH(32),.DEST_SYNC_FF(2),.SIM_ASSERT_CHK(1),.SIM_LOSSLESS_GRAY_CHK(0)) bad_cdc(.src_clk(rx_clk),.src_in_bin(malformed),.dest_clk(clk),.dest_out_bin(bad_host));
 (* ASYNC_REG="TRUE" *) reg [1:0] full_sync=0,busy_sync=3;
 always @(posedge clk)begin full_sync<={full_sync[0],full};busy_sync<={busy_sync[0],wr_busy};end
 assign s_axi_awready=rst_n&&!have_aw&&!s_axi_bvalid;
 assign s_axi_wready=rst_n&&!have_w&&!s_axi_bvalid;
 assign s_axi_arready=rst_n&&!s_axi_rvalid;
 always @(posedge clk)begin
  if(!rst_n)begin enabled<=0;pop<=0;have_aw<=0;have_w<=0;aw<=0;wd<=0;ws<=0;s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rresp<=0;s_axi_rdata<=0;end
  else begin
   pop<=0;
   if(s_axi_bvalid&&s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_rvalid&&s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_awvalid&&s_axi_awready)begin aw<=s_axi_awaddr;have_aw<=1;end
   if(s_axi_wvalid&&s_axi_wready)begin wd<=s_axi_wdata;ws<=s_axi_wstrb;have_w<=1;end
   if(have_aw&&have_w&&!s_axi_bvalid)begin
    have_aw<=0;have_w<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    if(aw==4&&ws==15&&wd<=1)enabled<=wd[0];
    else if(aw==16&&ws==15&&wd==1&&!empty&&!rd_busy)pop<=1;
    else s_axi_bresp<=2;
   end
   if(s_axi_arvalid&&s_axi_arready)begin
    s_axi_rvalid<=1;s_axi_rresp<=0;s_axi_rdata<=0;
    case(s_axi_araddr)
     0:s_axi_rdata<=32'h51535001;
     4:s_axi_rdata<={31'd0,enabled};
     8:s_axi_rdata<={28'd0,rd_busy,busy_sync[1],full_sync[1],empty};
     12:s_axi_rdata<={25'd0,level};
     16:s_axi_rdata<=0;
     20:s_axi_rdata<=total_host;
     24:s_axi_rdata<=drop_host;
     28:s_axi_rdata<=bad_host;
     default:if(s_axi_araddr>=32&&s_axi_araddr<=52&&s_axi_araddr[1:0]==0&&!empty&&!rd_busy)
      s_axi_rdata<=head[(s_axi_araddr-32)*8+:32];else s_axi_rresp<=2;
    endcase
   end
  end
 end
endmodule
