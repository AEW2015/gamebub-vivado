module sram_clock_control #(parameter integer CLOCK_HZ=50000000)(
 input wire clk,rst_n,request,input wire [2:0] profile,input wire locked,heartbeat,
 output reg [2:0] selected,output reg mmcm_reset,ready,busy,fault);
 (* ASYNC_REG="TRUE" *) reg [1:0] lock_sync,heart_sync;
 reg last_heart;reg [31:0] timeout,quiet;reg [6:0] settle;reg [1:0] edges,state;
 always @(posedge clk)begin
  if(!rst_n)begin lock_sync<=0;heart_sync<=0;last_heart<=0;selected<=0;mmcm_reset<=1;ready<=0;busy<=1;fault<=0;timeout<=0;quiet<=0;settle<=0;edges<=0;state<=0;end
  else begin
   lock_sync<={lock_sync[0],locked};heart_sync<={heart_sync[0],heartbeat};last_heart<=heart_sync[1];
   if(heart_sync[1]!=last_heart)quiet<=0;else if(quiet<CLOCK_HZ/1000)quiet<=quiet+1'b1;
   if(request && (state==2 || state==3))begin selected<=profile;mmcm_reset<=1;ready<=0;busy<=1;fault<=0;timeout<=0;settle<=0;edges<=0;state<=0;end
   else case(state)
    0:begin if(settle==15)begin mmcm_reset<=0;state<=1;settle<=0;timeout<=0;edges<=0;end else settle<=settle+1'b1;end
    1:begin
     if(settle<63)settle<=settle+1'b1;
     if(lock_sync[1] && heart_sync[1]!=last_heart && edges<3)edges<=edges+1'b1;
     if(lock_sync[1] && edges==3 && settle==63)begin ready<=1;busy<=0;state<=2;quiet<=0;end
     else if(timeout==CLOCK_HZ/50)begin fault<=1;busy<=0;mmcm_reset<=1;state<=3;end
     else timeout<=timeout+1'b1;
    end
    2:if(!lock_sync[1] || quiet==CLOCK_HZ/1000)begin ready<=0;fault<=1;busy<=0;mmcm_reset<=1;state<=3;end
    3:begin ready<=0;end
   endcase
  end
 end
endmodule
