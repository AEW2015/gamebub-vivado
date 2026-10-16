`timescale 1ns/1ps
module tb_contract;
`ifdef OVERLAY
 localparam ENABLE=1;
`else
 localparam ENABLE=0;
`endif
 reg clk=0,pix=0,rst=0; always #2.5 clk=~clk; always #17 pix=~pix;
 reg [11:0] buttons=12'hfff;
 wire [3:0] dq; wire irq,gate;
 reg [11:0] aw=0,ar=0; reg av=0,wv=0,bready=0,rv=0,rready=0;
 reg [31:0] wd=0; reg [3:0] ws=15;
 wire awready,wready,bvalid,arready,rvalid; wire [1:0] br,rr; wire [31:0] rd;
 gamebub_esp32_v102 #(.C_ENABLE_OVERLAY_AXIS(ENABLE),.C_ENABLE_CPU_OVERLAY(ENABLE)) dut(
 .service_clk(clk),.service_resetn(rst),.qspi_sck(1'b0),.qspi_cs_n(1'b1),.qspi_dq(dq),
 .buttons_n(buttons),.cpu_irq(irq),.irq_gate(gate),
 .s_axi_awaddr(aw),.s_axi_awprot(3'b0),.s_axi_awvalid(av),.s_axi_awready(awready),
 .s_axi_wdata(wd),.s_axi_wstrb(ws),.s_axi_wvalid(wv),.s_axi_wready(wready),
 .s_axi_bresp(br),.s_axi_bvalid(bvalid),.s_axi_bready(bready),
 .s_axi_araddr(ar),.s_axi_arprot(3'b0),.s_axi_arvalid(rv),.s_axi_arready(arready),
 .s_axi_rdata(rd),.s_axi_rresp(rr),.s_axi_rvalid(rvalid),.s_axi_rready(rready),
 .overlay_clk(pix),.overlay_resetn(rst),.M_AXIS_OVERLAY_tready(1'b1));
 reg [31:0] value; reg [1:0] response; integer simultaneous=0;
 always @(posedge clk) if(rst && dut.commit && dut.aw_addr==12'h024 && dut.button_change) simultaneous=simultaneous+1;
 task read32(input [11:0] addr);
 integer n;
 begin
  @(negedge clk); ar=addr;rv=1;rready=0;
  @(posedge clk); while(!arready) @(posedge clk);
  @(negedge clk);rv=0;
  if(rvalid) $fatal(1,"unexpected unpipelined read");
  n=0;
  while(!rvalid) begin @(posedge clk); #1; n=n+1; end
  if(n!=2) $fatal(1,"read latency expected2 got%0d",n);
  value=rd;response=rr;
  repeat(3) begin @(posedge clk); #1;
   if(!rvalid || rd!==value || rr!==response || arready) $fatal(1,"unstable stalled read");
  end
  @(negedge clk);rready=1; @(negedge clk);rready=0;
 end endtask
 task write32(input [11:0] addr,input [31:0] data,input [1:0] expected);
 begin
  @(negedge clk);aw=addr;av=1;bready=0;
  @(posedge clk);while(!awready) @(posedge clk);
  @(negedge clk);av=0;
  repeat(2) @(negedge clk);wd=data;wv=1;
  @(posedge clk);while(!wready) @(posedge clk);
  @(negedge clk);wv=0;
  while(!bvalid) @(negedge clk);
  if(br!==expected) $fatal(1,"BRESP addr%x expected%0d got%0d",addr,expected,br);
  repeat(3) begin @(negedge clk); if(!bvalid || br!==expected || awready || wready) $fatal(1,"unstable stalled write");end
  bready=1; @(negedge clk);bready=0;
 end endtask
`ifdef OVERLAY
 wire [31:0] bitmap0,bitmaplast;
 genvar k;
 for(k=0;k<16;k=k+1)begin
  assign bitmap0[k*2+:2]=dut.overlay_axis_enabled.overlay_stream.cpu_bitmap.lanes[k].bitmap[0];
  assign bitmaplast[k*2+:2]=dut.overlay_axis_enabled.overlay_stream.cpu_bitmap.lanes[k].bitmap[5759];
 end
`endif
 initial begin
  repeat(5) @(negedge clk);rst=1;repeat(8) @(negedge clk);
  read32(0); if(value!==32'h47424553 || response) $fatal(1,"ID");
  read32(4); if(value!==32'h00010005 || response) $fatal(1,"ABI");
  read32(12); if(value!==200000000 || response) $fatal(1,"clock");
  read32(1); if(response!==2 || value!==0) $fatal(1,"misaligned read must SLVERR");
  write32(0,0,2); // negative read-only write
  write32(12'h028,1,0);
  @(negedge clk);buttons[11]=0;repeat(8) @(negedge clk);
  read32(12'h020);if(value!==1) $fatal(1,"button mapping");
  if(!irq) $fatal(1,"press IRQ missing");
  write32(12'h024,1,0);repeat(3) @(negedge clk);if(irq) $fatal(1,"ack did not clear");
  @(negedge clk);buttons[11]=1;repeat(8) @(negedge clk);if(!irq) $fatal(1,"release did not reassert");
  // CPU event wins when change is simultaneous with CPU W1C commit.
  fork
   write32(12'h024,1,0);
   begin @(negedge clk);repeat(2) @(negedge clk);buttons[10]=0;end
  join
  if(simultaneous!=1) $fatal(1,"test failed to align physical change with W1C commit");
  read32(12'h024);if(value!==1) $fatal(1,"simultaneous change lost to W1C");
  write32(12'h024,1,0);
`ifdef OVERLAY
  read32(12'h214); if(value!==32'h434f5632) $fatal(1,"COV2 ID");
  write32(12'h204,5760,2);write32(12'h224,92160,2);
  write32(12'h204,0,0);write32(12'h208,32'haaaa5555,0);
  repeat(3) @(negedge clk);if(bitmap0!==32'haaaa5555) $fatal(1,"packed pattern");
  write32(12'h224,92159,0);write32(12'h228,3,0);
  repeat(3) @(negedge clk);if(bitmaplast[31:30]!==3) $fatal(1,"lastpixel");
  read32(12'h224);if(value!==0) $fatal(1,"pixel index wrap");
  write32(12'h200,1,0);
`else
  read32(12'h214);if(value!==0) $fatal(1,"absent COV2 ID");
  write32(12'h200,1,2);write32(12'h204,0,2);write32(12'h208,0,2);write32(12'h228,3,2);
`endif
  $display("ESP32_EXACT_RTL_PASS overlay=%0d read_pipeline stalled_axi irq_w1c reassert capability bounds",ENABLE);
  $finish;
 end
 initial begin #100000;$fatal(1,"test timeout");end
endmodule
