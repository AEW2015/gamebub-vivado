// Functional regenerated MCLK only, no setup/hold or analog timing checks.
module ODDR #(parameter DDR_CLK_EDGE="SAME_EDGE")
 (output reg Q,input C,CE,D1,D2,R,S);
 always @(C or posedge R or posedge S)
  if(R) Q<=0; else if(S) Q<=1; else if(CE) Q<=C?D1:D2;
endmodule
