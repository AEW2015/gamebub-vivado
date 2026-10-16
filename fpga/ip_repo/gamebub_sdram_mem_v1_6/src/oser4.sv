`timescale 1ns/1ps
// Four SDR bits, D1 first. TQ is beat-level SDR output-enable control.
module oser4 #(parameter bit RESET_BIT=0)(
 input wire clk,clk_div,rst,input wire [3:0] data,input wire tristate,
 output wire q,tq);
 OSERDESE2 #(.DATA_RATE_OQ("SDR"),.DATA_RATE_TQ("SDR"),.DATA_WIDTH(4),
  .TRISTATE_WIDTH(1),.SERDES_MODE("MASTER"),.INIT_OQ(RESET_BIT),
  .SRVAL_OQ(RESET_BIT),.INIT_TQ(1'b1),.SRVAL_TQ(1'b1)) ser(
  .CLK(clk),.CLKDIV(clk_div),.RST(rst),.OCE(1'b1),.TCE(1'b1),
  .D1(data[0]),.D2(data[1]),.D3(data[2]),.D4(data[3]),
  .D5(1'b0),.D6(1'b0),.D7(1'b0),.D8(1'b0),
  .T1(tristate),.T2(1'b1),.T3(1'b1),.T4(1'b1),
  .SHIFTIN1(1'b0),.SHIFTIN2(1'b0),.TBYTEIN(1'b0),
  .OQ(q),.TQ(tq),.OFB(),.TFB(),.TBYTEOUT(),.SHIFTOUT1(),.SHIFTOUT2());
endmodule
