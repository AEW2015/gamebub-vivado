`timescale 1ns/1ps
// Full-panel binary-alpha video join. Both inputs must use this clock/reset.
// Hold early SOF while independently draining old data on the other input.
// Unexpected SOF/EOL reacquires alignment and sets a sticky diagnostic.
module gamebub_axis_overlay_compositor #(parameter integer RGB_PACKING=0)(
 input wire clk,resetn,
 input wire [23:0] base_data,
 input wire base_valid,base_user,base_last,output wire base_ready,
 input wire [31:0] overlay_data,
 input wire overlay_valid,overlay_user,overlay_last,output wire overlay_ready,
 output reg [23:0] data=0,
 output reg valid=0,user=0,last=0,input wire ready,
 output reg framing_error=0,output wire overlay_visible
);
 reg aligned=0;reg [8:0] x=0;reg [9:0] y=0;
 reg frame_opaque=0,previous_opaque=0;
 wire slot=!valid || ready;
 wire both=base_valid && overlay_valid;
 wire first=x==0 && y==0;
 wire good=base_user==first && overlay_user==first &&
           base_last==(x==479) && overlay_last==(x==479);
 wire [23:0] overlay_rgb=RGB_PACKING?{overlay_data[23:16],overlay_data[7:0],overlay_data[15:8]}:overlay_data[23:0];
 assign base_ready=resetn && (aligned?(slot && overlay_valid && good):!base_user);
 assign overlay_ready=resetn && (aligned?(slot && base_valid && good):!overlay_user);
 assign overlay_visible=frame_opaque|previous_opaque;
 always @(posedge clk) begin
  if(!resetn) begin
   aligned<=0;x<=0;y<=0;framing_error<=0;frame_opaque<=0;previous_opaque<=0;
   valid<=0;data<=0;user<=0;last<=0;
  end else begin
   if(slot) valid<=0;
   if(!aligned) begin
    x<=0;y<=0;
    if(both && base_user && overlay_user) aligned<=1;
   end else if(both && slot) begin
    if(!good) begin aligned<=0;framing_error<=1;end
    else begin
     valid<=1;user<=first;last<=x==479;
     data<=overlay_data[31]?overlay_rgb:base_data;
     if(first) begin previous_opaque<=frame_opaque;frame_opaque<=overlay_data[31];end
     else if(overlay_data[31]) frame_opaque<=1;
     if(x==479) begin x<=0;y<=y==799?0:y+1'b1;end else x<=x+1'b1;
    end
   end
  end
 end
endmodule
