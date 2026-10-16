`timescale 1ns/1ps
module sram_test_engine # (parameter integer CLOCK_HZ=50000000)(
 input wire clk,rst_n,run,restart,clear,abort,
 input wire [17:0] base,input wire [18:0] count,input wire [3:0] pattern,
 input wire [2:0] mode,input wire descending,stop_on_error,input wire [15:0] seed,
 input wire [31:0] dwell_ms,epoch,
 output wire quiescent,output wire busy,output reg fault,
 output reg req_valid,input wire req_ready,output reg req_write,
 output reg [17:0] req_addr,output reg [15:0] req_data,output reg [1:0] req_be,
 input wire rsp_valid,output wire rsp_ready,input wire [15:0] rsp_data,
 output reg [31:0] work,output wire [31:0] total_work,
 output reg [31:0] passes,completed,aborts,failures,reads,writes,
 output reg [63:0] active_cycles,payload_bytes,
 output reg first_valid,output reg [17:0] first_addr,output reg [15:0] first_expected,first_actual,
 output reg [31:0] first_epoch,output reg [7:0] first_stage,
 output reg [511:0] dq_errors,output wire [7:0] stage,output wire [17:0] cursor,
 output wire [3:0] debug_state);
 import sram_test_pkg::*;
 localparam READY=0,ISSUE=1,WAIT_RSP=2,ADVANCE=3,DWELL=4,FINISH=5,HALTED=6;
 reg [3:0] state;
 reg [5:0] phase;
 reg substep,pass_bad,pass_started;
 reg [18:0] index;
 reg [15:0] lfsr,expected;
 reg [31:0] watchdog,dwell_left;
 reg [31:0] ms_div;
 wire backwards=(mode==2)?(phase==3 || phase==4):descending;
 wire [18:0] offset=backwards?(count-1'b1-index):index;
 wire [17:0] address=base+offset[17:0];
 wire [15:0] pat=pattern_data(pattern,address,lfsr);
 assign cursor=address;
 assign stage={1'b0,phase,substep};
 assign debug_state=state;
 assign quiescent=state==READY || state==DWELL || state==HALTED;
 assign busy=pass_started && state!=HALTED;
 assign rsp_ready=state==WAIT_RSP || state==HALTED;
 assign total_work=mode==1?({13'd0,count}*7):mode==2?({13'd0,count}*10):mode==3?({13'd0,count}*36):({13'd0,count}*2);
 integer j;
 task automatic reset_pass;
  begin phase<=0;substep<=0;index<=0;lfsr<=seed==0?16'h1:seed;work<=0;pass_bad<=0;pass_started<=0;state<=READY;req_valid<=0;watchdog<=0;dwell_left<=0;ms_div<=0;end
 endtask
 always @(posedge clk)begin
  if(!rst_n)begin
   reset_pass();fault<=0;req_addr<=0;req_data<=0;req_be<=0;req_write<=0;expected<=0;
   passes<=0;completed<=0;aborts<=0;failures<=0;reads<=0;writes<=0;active_cycles<=0;payload_bytes<=0;
   first_valid<=0;first_addr<=0;first_expected<=0;first_actual<=0;first_epoch<=0;first_stage<=0;dq_errors<=0;
  end else begin
   if(clear)begin
    passes<=0;completed<=0;aborts<=0;failures<=0;reads<=0;writes<=0;active_cycles<=0;payload_bytes<=0;
    first_valid<=0;first_addr<=0;first_expected<=0;first_actual<=0;first_epoch<=0;first_stage<=0;dq_errors<=0;
   end
   if(run && state!=HALTED && !(&active_cycles))active_cycles<=active_cycles+1'b1;
   if(restart)begin
    if(pass_started)aborts<=sat_inc(aborts);
    reset_pass();fault<=0;
   end else if(abort)begin if(pass_started)aborts<=sat_inc(aborts);pass_started<=0;fault<=1;req_valid<=0;state<=HALTED;end else case(state)
    READY:if(run && !fault)begin
     pass_started<=1;req_addr<=address;req_be<=3;expected<=pat;req_data<=pat;
     if(mode==1)begin
      case(phase)
       0:begin req_write<=1;req_data<=16'h5555;end
       1:begin req_write<=1;req_be<=1;req_data<=16'haaaa;end
       2:begin req_write<=0;expected<=16'h55aa;end
       3:begin req_write<=1;req_be<=2;req_data<=16'hcccc;end
       4:begin req_write<=0;expected<=16'hccaa;end
       5:begin req_write<=1;req_be<=0;req_data<=16'hffff;end
       default:begin req_write<=0;expected<=16'hccaa;end
      endcase
     end else if(mode==2)begin
      req_write<=phase==0 || ((phase>=1 && phase<=4) && substep);
      expected<=(phase==2 || phase==4)?16'hffff:16'h0000;
      req_data<=(phase==1 || phase==3)?16'hffff:16'h0000;
     end else if(mode==3)begin
      req_write<=!phase[0];req_data<=address[phase>>1]?16'hffff:16'h0000;
      expected<=address[phase>>1]?16'hffff:16'h0000;
     end else if(mode==4)req_write<=!substep;
     else req_write<=phase==0;
     req_valid<=1;state<=ISSUE;watchdog<=0;
    end
    ISSUE:begin
     if(req_ready)begin req_valid<=0;state<=WAIT_RSP;watchdog<=0;end
     else if(watchdog==CLOCK_HZ/100)begin fault<=1;req_valid<=0;state<=HALTED;pass_started<=0;aborts<=sat_inc(aborts);end
     else watchdog<=watchdog+1'b1;
    end
    WAIT_RSP:begin
     if(rsp_valid)begin
      work<=work+1'b1;
      if(req_write)writes<=sat_inc(writes);else reads<=sat_inc(reads);
      if(payload_bytes<=64'hfffffffffffffffd)payload_bytes<=payload_bytes+{63'd0,req_be[0]}+{63'd0,req_be[1]};else payload_bytes<=64'hffffffffffffffff;
      if(!req_write && rsp_data!==expected)begin
       failures<=sat_inc(failures);pass_bad<=1;
       for(j=0;j<16;j=j+1)if(rsp_data[j]!==expected[j])dq_errors[j*32+:32]<=sat_inc(dq_errors[j*32+:32]);
       if(!first_valid)begin first_valid<=1;first_addr<=req_addr;first_expected<=expected;first_actual<=rsp_data;first_epoch<=epoch;first_stage<=stage;end
       if(stop_on_error)begin fault<=1;state<=HALTED;pass_started<=0;aborts<=sat_inc(aborts);end else state<=ADVANCE;
      end else state<=ADVANCE;
     end else if(watchdog==CLOCK_HZ/100)begin fault<=1;state<=HALTED;pass_started<=0;aborts<=sat_inc(aborts);end
     else watchdog<=watchdog+1'b1;
    end
    ADVANCE:begin
     if((mode==2 && phase>=1 && phase<=4 && !substep) || (mode==4 && !substep))begin substep<=1;state<=READY;end
     else begin
      substep<=0;lfsr<=prbs_next(lfsr);
      if(index+1'b1<count)begin index<=index+1'b1;state<=READY;end
      else begin
       index<=0;lfsr<=seed==0?16'h1:seed;
       if((mode==0 && phase==1)||(mode==1 && phase==6)||(mode==2 && phase==5)||(mode==3 && phase==35)||mode==4)state<=FINISH;
       else begin
        phase<=phase+1'b1;
        if(mode==0 && phase==0 && dwell_ms!=0)begin dwell_left<=dwell_ms;ms_div<=0;state<=DWELL;end
        else state<=READY;
       end
      end
     end
    end
    DWELL:if(run)begin
     if(ms_div==CLOCK_HZ/1000-1)begin ms_div<=0;if(dwell_left==1)begin dwell_left<=0;state<=READY;end else dwell_left<=dwell_left-1'b1;end
     else ms_div<=ms_div+1'b1;
    end
    FINISH:begin completed<=sat_inc(completed);if(!pass_bad)passes<=sat_inc(passes);reset_pass();end
    HALTED:begin req_valid<=0;end
    default:begin fault<=1;state<=HALTED;req_valid<=0;end
   endcase
  end
 end
endmodule
