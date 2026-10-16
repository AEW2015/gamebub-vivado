`timescale 1ns/1ps
// One eight-slot word per 100 MHz CLKDIV; D1 is the earliest 1.25 ns slot.
module sram_serdes_out #(parameter INIT=1'b0)(
 input wire clk,io_clk,rst_n,input wire [7:0] word,input wire tristate,
 output wire serial,tri_out);
 OSERDESE2 #(.DATA_RATE_OQ("DDR"),.DATA_WIDTH(8),.SERDES_MODE("MASTER"),
  .DATA_RATE_TQ("BUF"),.TRISTATE_WIDTH(1),.INIT_OQ(INIT),.SRVAL_OQ(INIT),.INIT_TQ(1'b1),.SRVAL_TQ(1'b1))
 ser(.CLK(io_clk),.CLKDIV(clk),.RST(!rst_n),.OCE(1'b1),.TCE(1'b1),
  .D1(word[0]),.D2(word[1]),.D3(word[2]),.D4(word[3]),.D5(word[4]),.D6(word[5]),.D7(word[6]),.D8(word[7]),
  .T1(tristate),.T2(1'b1),.T3(1'b1),.T4(1'b1),.TBYTEIN(1'b0),.SHIFTIN1(1'b0),.SHIFTIN2(1'b0),.OQ(serial),.TQ(tri_out));
endmodule

module sram_serdes_in(input wire clk,io_clk,rst_n,serial,output wire [7:0] samples);
 ISERDESE2 #(.DATA_RATE("DDR"),.DATA_WIDTH(8),.INTERFACE_TYPE("NETWORKING"),
  .IOBDELAY("NONE"),.NUM_CE(2),.SERDES_MODE("MASTER"))
 ser(.CLK(io_clk),.CLKB(!io_clk),.CLKDIV(clk),.RST(!rst_n),.CE1(1'b1),.CE2(1'b1),
  .D(serial),.DDLY(1'b0),.BITSLIP(1'b0),.CLKDIVP(1'b0),.OCLK(1'b0),.OCLKB(1'b0),
  .DYNCLKDIVSEL(1'b0),.DYNCLKSEL(1'b0),.OFB(1'b0),.SHIFTIN1(1'b0),.SHIFTIN2(1'b0),
  .Q1(samples[7]),.Q2(samples[6]),.Q3(samples[5]),.Q4(samples[4]),
  .Q5(samples[3]),.Q6(samples[2]),.Q7(samples[1]),.Q8(samples[0]));
endmodule
