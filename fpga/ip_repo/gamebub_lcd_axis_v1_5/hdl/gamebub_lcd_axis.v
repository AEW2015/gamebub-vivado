`timescale 1ns/1ps
// v1.4: official-derived fixed timing by default; optional native ESP32 AXIS overlay.
// AXIS mode adds registers only; the framebuffer remains in the ESP32 IP.
module gamebub_lcd_axis #(
 parameter integer C_ENABLE_OVERLAY=0,C_RGB_PACKING=0,C_TIMING_PROFILE=1
)(
 input wire pixel_clk,pixel_resetn,
 input wire [23:0] S_AXIS_VIDEO_tdata,
 input wire S_AXIS_VIDEO_tvalid,S_AXIS_VIDEO_tuser,S_AXIS_VIDEO_tlast,
 output wire S_AXIS_VIDEO_tready,
 input wire [31:0] S_AXIS_OVERLAY_tdata,
 input wire S_AXIS_OVERLAY_tvalid,S_AXIS_OVERLAY_tuser,S_AXIS_OVERLAY_tlast,
 output wire S_AXIS_OVERLAY_tready,
 output wire vblank,overlay_visible,stream_locked,underflow,framing_error,
 output wire lcd_dotclk,lcd_hsync,lcd_vsync,lcd_data_en,
 output wire [7:0] lcd_data_r,lcd_data_g,lcd_data_b
);
 // Fixed profiles; profile 1 is official-derived, not the adaptive upstream scheduler.
 localparam integer LCD_HSTART = C_TIMING_PROFILE == 1 ? 123 : 14;
 localparam integer LCD_VSTART = C_TIMING_PROFILE == 1 ? 6 : 24;
 localparam integer LCD_HTOTAL = C_TIMING_PROFILE == 1 ? 605 : 541;
 localparam integer LCD_VTOTAL = C_TIMING_PROFILE == 1 ? 809 : 834;
 wire [23:0] raster_data;
 wire raster_valid,raster_user,raster_last,raster_ready;
 wire join_error,axis_visible;
 generate if(C_ENABLE_OVERLAY) begin: axis_overlay
  gamebub_axis_overlay_compositor #(.RGB_PACKING(C_RGB_PACKING)) compositor(
   .clk(pixel_clk),.resetn(pixel_resetn),
   .base_data(S_AXIS_VIDEO_tdata),.base_valid(S_AXIS_VIDEO_tvalid),
   .base_user(S_AXIS_VIDEO_tuser),.base_last(S_AXIS_VIDEO_tlast),.base_ready(S_AXIS_VIDEO_tready),
   .overlay_data(S_AXIS_OVERLAY_tdata),.overlay_valid(S_AXIS_OVERLAY_tvalid),
   .overlay_user(S_AXIS_OVERLAY_tuser),.overlay_last(S_AXIS_OVERLAY_tlast),.overlay_ready(S_AXIS_OVERLAY_tready),
   .data(raster_data),.valid(raster_valid),.user(raster_user),.last(raster_last),.ready(raster_ready),
   .framing_error(join_error),.overlay_visible(axis_visible));
 end else begin: direct_video
  assign raster_data=S_AXIS_VIDEO_tdata;
  assign {raster_valid,raster_user,raster_last}={S_AXIS_VIDEO_tvalid,S_AXIS_VIDEO_tuser,S_AXIS_VIDEO_tlast};
  assign S_AXIS_VIDEO_tready=raster_ready;
  assign S_AXIS_OVERLAY_tready=1'b0;
  assign {join_error,axis_visible}=2'b0;
 end endgenerate
 wire hs,vs,de,raster_error;wire [23:0] rgb;wire [9:0] x,y;
 gamebub_axis_raster #(.RGB_PACKING(C_RGB_PACKING),
  .HSTART(LCD_HSTART),.VSTART(LCD_VSTART),.HTOTAL(LCD_HTOTAL),.VTOTAL(LCD_VTOTAL),
  .HSYNC(4),.VSYNC(4)) raster(
  .clk(pixel_clk),.resetn(pixel_resetn),.tdata(raster_data),
  .tvalid(raster_valid),.tuser(raster_user),.tlast(raster_last),.tready(raster_ready),
  .hs(hs),.vs(vs),.de(de),.rgb(rgb),.x(x),.y(y),
  .locked(stream_locked),.underflow(underflow),.framing_error(raster_error));
 assign framing_error=raster_error|join_error;
 assign overlay_visible=axis_visible;
 assign vblank=vs;
 (* IOB="TRUE" *) reg [26:0] outputs=0;
 always @(posedge pixel_clk) outputs<=pixel_resetn?{hs,vs,de,rgb}:27'd0;
 assign {lcd_hsync,lcd_vsync,lcd_data_en,lcd_data_r,lcd_data_g,lcd_data_b}=outputs;
 ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) dotclock(.Q(lcd_dotclk),.C(pixel_clk),.CE(1'b1),
  .D1(1'b1),.D2(1'b0),.R(1'b0),.S(1'b0));
endmodule
