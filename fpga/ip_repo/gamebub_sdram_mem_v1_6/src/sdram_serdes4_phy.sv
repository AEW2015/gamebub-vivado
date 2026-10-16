`timescale 1ns/1ps
module sdram_serdes4_phy #(parameter bit RAW_FIFO_ENABLE=1)(
 input wire clk,clk_div,read_clk,read_clk_div,refclk200,
 input wire rst_tx,rst_rx,rst_delay,
 input wire [95:0] tx_ca,input wire [63:0] tx_data,input wire tx_drive,
 input wire tap_load,input wire [79:0] tap_value,output wire [79:0] tap_actual,
 output wire delay_ready,
 input wire rx_store,output wire [63:0] rx_raw,
 input wire rx_ready,output wire rx_valid,output wire [63:0] rx_data,
 output wire rx_overflow,output wire rx_fifo_ready,
 output wire [12:0] sdram_a,output wire [1:0] sdram_bs,
 output wire [1:0] sdram_cke,sdram_cs_n,
 output wire sdram_ras_n,sdram_cas_n,sdram_we_n,sdram_ldqm,sdram_udqm,
 output wire sdram_clk,inout wire [15:0] sdram_dq);
 localparam [23:0] SAFE_CA={2'b11,2'b11,3'b111,2'b00,13'd0,2'b11};
 wire [23:0] ca_pins;
 assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n,
         sdram_bs,sdram_a,sdram_udqm,sdram_ldqm}=ca_pins;
 IDELAYCTRL delay_controller(.REFCLK(refclk200),.RST(rst_delay),.RDY(delay_ready));
 ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(1'b0),.SRTYPE("SYNC")) forward_clock(
  .C(clk),.CE(1'b1),.D1(1'b0),.D2(1'b1),.R(1'b0),.S(1'b0),.Q(sdram_clk));
 genvar i;
 generate for(i=0;i<24;i=i+1) begin:g_ca
  oser4 #(.RESET_BIT(SAFE_CA[i])) ser(.clk(clk),.clk_div(clk_div),.rst(rst_tx),
   .data({tx_ca[72+i],tx_ca[48+i],tx_ca[24+i],tx_ca[i]}),
   .tristate(1'b0),.q(ca_pins[i]),.tq());
 end
 for(i=0;i<16;i=i+1) begin:g_dq
  wire out_q,out_t,raw,delayed;
  wire [3:0] samples;
  oser4 ser(.clk(clk),.clk_div(clk_div),.rst(rst_tx),
   .data({tx_data[48+i],tx_data[32+i],tx_data[16+i],tx_data[i]}),
   .tristate(!tx_drive),.q(out_q),.tq(out_t));
  IOBUF pad(.IO(sdram_dq[i]),.I(out_q),.T(out_t),.O(raw));
  IDELAYE2 #(.DELAY_SRC("IDATAIN"),.IDELAY_TYPE("VAR_LOAD"),.IDELAY_VALUE(0),
   .HIGH_PERFORMANCE_MODE("TRUE"),.REFCLK_FREQUENCY(200.0),.SIGNAL_PATTERN("DATA")) delay(
   .C(clk_div),.LD(tap_load),.CNTVALUEIN(tap_value[5*i+:5]),.CNTVALUEOUT(tap_actual[5*i+:5]),
   .IDATAIN(raw),.DATAIN(1'b0),.DATAOUT(delayed),.CE(1'b0),.INC(1'b0),
   .LDPIPEEN(1'b0),.REGRST(rst_tx),.CINVCTRL(1'b0));
  ISERDESE2 #(.DATA_RATE("SDR"),.DATA_WIDTH(4),.INTERFACE_TYPE("NETWORKING"),
   .IOBDELAY("IFD"),.NUM_CE(1),.SERDES_MODE("MASTER")) des(
   .CLK(read_clk),.CLKB(!read_clk),.CLKDIV(read_clk_div),.CLKDIVP(1'b0),
   .RST(rst_rx),.CE1(1'b1),.CE2(1'b1),.BITSLIP(1'b0),
   .D(1'b0),.DDLY(delayed),.OCLK(1'b0),.OCLKB(1'b0),.OFB(1'b0),
   .DYNCLKDIVSEL(1'b0),.DYNCLKSEL(1'b0),.SHIFTIN1(1'b0),.SHIFTIN2(1'b0),
   .Q1(samples[3]),.Q2(samples[2]),.Q3(samples[1]),.Q4(samples[0]),
   .Q5(),.Q6(),.Q7(),.Q8(),.O(),.SHIFTOUT1(),.SHIFTOUT2());
  assign {rx_raw[48+i],rx_raw[32+i],rx_raw[16+i],rx_raw[i]}=samples;
 end endgenerate
 generate if(RAW_FIFO_ENABLE)begin:g_raw_fifo
 reg overflow_reg=0;
 assign rx_overflow=overflow_reg;
 wire full,empty,wr_busy,rd_busy;
 assign rx_fifo_ready=!wr_busy;
 assign rx_valid=!empty && !rd_busy;
 // FIFO reset must encompass the TX and RX reset/reconfiguration interval.
 // It is asserted while both clocks still run; integration must sequence this.
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("distributed"),.FIFO_WRITE_DEPTH(32),
  .WRITE_DATA_WIDTH(64),.READ_DATA_WIDTH(64),.READ_MODE("fwft"),
  .FIFO_READ_LATENCY(0),.CDC_SYNC_STAGES(2),.USE_ADV_FEATURES("0000"),
  .DOUT_RESET_VALUE("0"),.ECC_MODE("no_ecc")) read_fifo(
  .rst(rst_rx),.wr_clk(read_clk_div),.rd_clk(clk_div),
  .din(rx_raw),.wr_en(rx_store && !wr_busy && !full),
  .dout(rx_data),.rd_en(rx_ready && rx_valid),.full(full),.empty(empty),
  .wr_rst_busy(wr_busy),.rd_rst_busy(rd_busy),.sleep(1'b0),
  .injectsbiterr(1'b0),.injectdbiterr(1'b0),.almost_empty(),.almost_full(),
  .data_valid(),.dbiterr(),.sbiterr(),.overflow(),.underflow(),
  .prog_empty(),.prog_full(),.rd_data_count(),.wr_data_count(),.wr_ack());
 always @(posedge read_clk_div) begin
  if(rst_rx)overflow_reg<=0;
  else if(rx_store && (full || wr_busy))overflow_reg<=1;
 end
 end else begin:g_no_raw_fifo
  assign rx_fifo_ready=1'b1;
  assign rx_valid=1'b0;
  assign rx_data=64'd0;
  assign rx_overflow=1'b0;
 end endgenerate
endmodule
