`timescale 1ns/1ps
// ESP32 ARGB1555 writes -> repeated native-panel 480x800 AXI video frames.
// AMD RGBA packing, one pixel/beat: [31:24]A [23:16]R [15:8]B [7:0]G.
// TUSER=SOF, TLAST=EOL. No blanking beats. QSPI never sees TREADY.
// Configuration initializes transparent. Soft resets flush the streaming
// pipeline, not the framebuffer. Live asynchronous writes can tear (as stock).
module esp32_overlay_axis #(parameter integer MONOCHROME=1,CPU_OVERLAY=0)(
 input wire service_clk,service_resetn,
 input wire ov_wr,input wire [17:0] ov_addr,input wire [15:0] ov_data,
 input wire cpu_enable,cpu_write,input wire [12:0] cpu_word_address,
 input wire [31:0] cpu_word_data,input wire [15:0] cpu_pixel_strobe,
 input wire axis_clk,axis_resetn,input wire tready,
 output reg [31:0] tdata=0,
 output reg tvalid=0,tuser=0,tlast=0
);
 localparam integer BITS=MONOCHROME?2:16;
 (* ram_style="block" *) reg [BITS-1:0] pixels0[0:32767];
 (* ram_style="block" *) reg [BITS-1:0] pixels1[0:32767];
 (* ram_style="block" *) reg [BITS-1:0] pixels2[0:32767];
 integer i;
 initial for(i=0;i<32768;i=i+1) begin
  pixels0[i]=0;pixels1[i]=0;pixels2[i]=0;
 end
 reg [2:0] write_valid=0;
 reg [14:0] write_address=0;
 reg [BITS-1:0] write_data=0;
 // Shift/add luma approximation in RGB5 units: white when 2R+5G+B>=128.
 // Preserve the original alpha bit independently, including opaque black.
 wire [7:0] brightness={2'b0,ov_data[14:10],1'b0}+
                       {1'b0,ov_data[9:5],2'b0}+
                       {3'b0,ov_data[9:5]}+{3'b0,ov_data[4:0]};
 wire white=brightness>=8'd128;
 always @(posedge service_clk) begin
  write_valid[0]<=service_resetn && ov_wr && !ov_addr[0] && ov_addr[17:1]<17'd32768;
  write_valid[1]<=service_resetn && ov_wr && !ov_addr[0] && ov_addr[17:1]>=17'd32768 && ov_addr[17:1]<17'd65536;
  write_valid[2]<=service_resetn && ov_wr && !ov_addr[0] && ov_addr[17:1]>=17'd65536 && ov_addr[17:1]<17'd86400;
  write_address<=ov_addr[15:1];
  write_data<=MONOCHROME?{ov_data[15],white}:ov_data;
  if(service_resetn && write_valid[0]) pixels0[write_address]<=write_data;
  if(service_resetn && write_valid[1]) pixels1[write_address]<=write_data;
  if(service_resetn && write_valid[2]) pixels2[write_address]<=write_data;
 end
 reg [8:0] x=0;
 reg [9:0] y=0;
 // Match the stock native-panel placement: landscape x=12..731, y=0..479.
 wire coordinate_valid=y>=12 && y<732;
 wire [16:0] row={9'b0,x[8:1]};
 wire [9:0] relative_y=y-10'd12;
 wire [16:0] address=(row<<8)+(row<<6)+(row<<5)+(row<<3)+{8'b0,relative_y[9:1]};
 reg [16:0] read_address=0;
 reg [BITS-1:0] pixel0,pixel1,pixel2;
 reg [1:0] read_bank=0;
 reg valid1=0,valid2=0,inside1=0,inside2=0;
 reg sof1=0,sof2=0,eol1=0,eol2=0;
 wire [BITS-1:0] stored_pixel=read_bank==0?pixel0:(read_bank==1?pixel1:pixel2);
 wire [15:0] pixel;
 generate if(MONOCHROME) begin: mono_expand
  assign pixel={stored_pixel[1],{15{stored_pixel[0]}}};
 end else begin: color_expand
  assign pixel=stored_pixel;
 end endgenerate
 wire [7:0] r={pixel[14:10],pixel[14:12]};
 wire [7:0] g={pixel[9:5],pixel[9:7]};
 wire [7:0] b={pixel[4:0],pixel[4:2]};
 wire advance=!tvalid || tready;
 // CPU's packed 384x240 bitmap is independent of the ESP32 framebuffer.
 // 16 pixels/word, 24 words/row. Each pixel is {opaque,white}, LSB first.
 (* ASYNC_REG="TRUE" *) reg [1:0] cpu_enable_sync=0;
 always @(posedge axis_clk)begin
  if(!axis_resetn)cpu_enable_sync<=0;
  else cpu_enable_sync<={cpu_enable_sync[0],cpu_enable};
 end
 reg cpu_inside1=0,cpu_inside2=0;
 wire [9:0] cpu_relative_y=y-10'd16;
 wire [12:0] cpu_row={5'd0,x[8:1]};
 wire cpu_coordinate_valid=y>=16 && y<784;
 reg [12:0] cpu_read_address=0;
 reg [3:0] cpu_bit1=0,cpu_bit2=0;
 wire [31:0] cpu_pixel_word;
 wire [1:0] cpu_pixel=cpu_pixel_word[{cpu_bit2,1'b0}+:2];
 // Break AXI decode/index/mask -> RAM enable/address/data into two short
 // service-clock paths. Earliest B handshake coincides with this RAM write.
 reg cpu_write_pending=0;
 reg [12:0] cpu_write_address=0;
 reg [31:0] cpu_write_data=0;
 reg [15:0] cpu_write_mask=0;
 always @(posedge service_clk)begin
  if(!service_resetn)begin
   cpu_write_pending<=0;cpu_write_address<=0;cpu_write_data<=0;cpu_write_mask<=0;
  end else begin
   // The AXI wrapper validates both indices before asserting cpu_write.
   cpu_write_pending<=cpu_write;
   cpu_write_address<=cpu_word_address;
   cpu_write_data<=cpu_word_data;
   cpu_write_mask<=cpu_pixel_strobe;
  end
 end
 genvar lane;
 generate if(CPU_OVERLAY)begin: cpu_bitmap
  for(lane=0;lane<16;lane=lane+1)begin: lanes
   (* ram_style="block" *) reg [1:0] bitmap[0:5759];
   reg [1:0] read_pixel=0;
   integer n;
   initial for(n=0;n<5760;n=n+1)bitmap[n]=0;
   always @(posedge service_clk)
    if(service_resetn && cpu_write_pending && cpu_write_mask[lane])
     bitmap[cpu_write_address]<=cpu_write_data[2*lane+:2];
   always @(posedge axis_clk)if(advance)read_pixel<=bitmap[cpu_read_address];
   assign cpu_pixel_word[2*lane+:2]=read_pixel;
  end
 end else begin: no_cpu_bitmap
  assign cpu_pixel_word=0;
 end endgenerate
 // Common pipeline enable keeps BRAM data, coordinates and sidebands aligned
 // through arbitrary stalls. Once primed, throughput is one pixel/clock.
 always @(posedge axis_clk) begin
  if(advance) begin
   pixel0<=pixels0[read_address[14:0]];
   pixel1<=pixels1[read_address[14:0]];
   pixel2<=pixels2[read_address[14:0]];
   read_bank<=read_address[16:15];
  end
  if(!axis_resetn) begin
   x<=0;y<=0;read_address<=0;
   valid1<=0;valid2<=0;inside1<=0;inside2<=0;
   sof1<=0;sof2<=0;eol1<=0;eol2<=0;
   tvalid<=0;tdata<=0;tuser<=0;tlast<=0;
   cpu_inside1<=0;cpu_inside2<=0;cpu_read_address<=0;cpu_bit1<=0;cpu_bit2<=0;
  end else if(advance) begin
   if(x==479) begin x<=0;y<=y==799?0:y+1'b1;end else x<=x+1'b1;
   read_address<=coordinate_valid?address:17'd0;
   cpu_read_address<=cpu_coordinate_valid?((cpu_row<<4)+(cpu_row<<3)+{8'd0,cpu_relative_y[9:5]}):13'd0;
   cpu_bit1<=cpu_relative_y[4:1];cpu_bit2<=cpu_bit1;
   cpu_inside1<=CPU_OVERLAY && cpu_enable_sync[1] && cpu_coordinate_valid;cpu_inside2<=cpu_inside1;
   valid1<=1;valid2<=valid1;
   inside1<=coordinate_valid;inside2<=inside1;
   sof1<=(x==0 && y==0);sof2<=sof1;
   eol1<=x==479;eol2<=eol1;
   tvalid<=valid2;tuser<=sof2;tlast<=eol2;
   tdata<=(inside2 && pixel[15])?{8'hff,r,b,g}:
           // No hardware rectangle: software controls opacity for every pixel.
           (cpu_inside2?{{8{cpu_pixel[1]}},{24{cpu_pixel[0]}}}:
            (inside2?{8'h00,r,b,g}:32'd0));
  end
 end
endmodule
