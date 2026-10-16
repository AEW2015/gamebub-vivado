`timescale 1ns/1ps
// Passive mode-0 bus observer. No output enable and no protocol responses.
// 200 MHz sampling domain; firmware data rates are 10/16/20/40 MHz.
// One summary per CS: meta, address, complete-word count, first/last raw word,
// and start timestamp (200 MHz ticks). Not a lossless payload recorder.
module qspi_sniffer_capture(
 input wire clk,rst_n,enable,qspi_sck,qspi_cs_n,input wire [3:0] qspi_dq,
 output reg valid,output reg [191:0] record);
 (* ASYNC_REG="TRUE" *) reg [1:0] sck_sync=0,cs_sync=3;
 (* ASYNC_REG="TRUE" *) reg [3:0] dq_meta=0,dq_sync=0;
 (* ASYNC_REG="TRUE" *) reg [1:0] enable_sync=0;
 reg sck_prev=0,cs_prev=1,active=0;
 reg [2:0] warm=0;reg seen_idle=0;
 reg [2:0] state=0,lanes=1;
 reg [6:0] bits=0,word_bits=32;
 reg [7:0] command=0;
 reg [31:0] shift=0,address=0,words=0,first_word=0,last_word=0,ticks=0,started=0;
 wire rise=sck_sync[1]&&!sck_prev;
 wire [7:0] command_next={command[6:0],dq_sync[0]};
 // Single-lane reads return on DQ1 (MISO), while command/address use DQ0.
 wire serial_bit=(state==3 && command[0])?dq_sync[1]:dq_sync[0];
 wire [31:0] shifted=lanes==4?{shift[27:0],dq_sync}:lanes==2?{shift[29:0],dq_sync[1:0]}:{shift[30:0],serial_bit};
 wire [7:0] flags={4'd0,(state==4),(state==2),(state==3 && bits!=0),(state<2)};
 always @(posedge clk)begin
  if(!rst_n)begin
   sck_sync<=0;cs_sync<=3;dq_meta<=0;dq_sync<=0;enable_sync<=0;
   sck_prev<=0;cs_prev<=1;active<=0;warm<=0;seen_idle<=0;state<=0;lanes<=1;bits<=0;word_bits<=32;
   command<=0;shift<=0;address<=0;words<=0;first_word<=0;last_word<=0;ticks<=0;started<=0;valid<=0;record<=0;
  end else begin
   sck_sync<={sck_sync[0],qspi_sck};cs_sync<={cs_sync[0],qspi_cs_n};
   dq_meta<=qspi_dq;dq_sync<=dq_meta;enable_sync<={enable_sync[0],enable};
   sck_prev<=sck_sync[1];cs_prev<=cs_sync[1];ticks<=ticks+1'b1;valid<=0;warm<={warm[1:0],1'b1};
   if(warm[2]&&cs_sync[1])seen_idle<=1;
   if(cs_prev&&!cs_sync[1])begin
    active<=enable_sync[1]&&seen_idle;state<=0;bits<=0;command<=0;shift<=0;address<=0;words<=0;
    first_word<=0;last_word<=0;started<=ticks;
   end else if(!cs_prev&&cs_sync[1])begin
    active<=0;
    if(active)begin valid<=1;record<={started,last_word,first_word,words,address,8'd0,flags,8'd0,command};end
   end else if(active&&!cs_sync[1]&&rise)begin
    case(state)
     0:begin
      command<=command_next;
      if(bits==7)begin
       bits<=0;lanes<=command_next[6:5]==2?4:command_next[6:5]==1?2:1;
       word_bits<=command_next[2:1]==2?32:command_next[2:1]==1?16:8;
       state<=(command_next[7] || command_next[6:5]==3 || command_next[2:1]==3)?4:1;
      end else bits<=bits+1'b1;
     end
     1:begin
      shift<=shifted;
      if(bits+lanes==32)begin address<=shifted;shift<=0;bits<=0;state<=command[0]?2:3;end
      else bits<=bits+lanes;
     end
     2:begin // Eight dummy bytes, at selected lane width.
      if(bits+lanes==64)begin bits<=0;state<=3;end else bits<=bits+lanes;
     end
     3:begin
      shift<=shifted;
      if(bits+lanes==word_bits)begin
       if(words==0)first_word<=shifted;
       last_word<=shifted;words<=words+1'b1;bits<=0;shift<=0;
      end else bits<=bits+lanes;
     end
     default:;
    endcase
   end
  end
 end
endmodule
