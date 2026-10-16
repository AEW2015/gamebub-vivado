`timescale 1ns/1ps
// All ports in command-quarter clock domain. No switching controller owner
// during a burst or an active test. PARK is idle ownership, not self-refresh.
module s4_shared_backend(
 input wire clk_div,rst,mem_valid,input wire [431:0] mem_data,
 output reg mem_done=0,output reg [1279:0] mem_response=0,
 input wire initialized,delay_ready,fatal,input wire [1151:0] telemetry,input wire [79:0] tap_actual,
 output reg [351:0] configuration=0,output reg start=0,abort_run=0,tap_load=0,
 output reg parked=0,
 input wire test_valid,test_write,input wire [23:0] test_addr,input wire [127:0] test_data,
 input wire [15:0] test_mask,output wire test_ready,
 output wire test_rsp_valid,input wire test_rsp_ready,
 output wire [127:0] test_rsp_data,output wire [2:0] test_rsp_status,
 output wire req_valid,req_write,output wire [23:0] req_addr,
 output wire [127:0] req_data,output wire [15:0] req_mask,input wire req_ready,
 input wire rsp_valid,output wire rsp_ready,input wire [127:0] rsp_data,input wire [2:0] rsp_status);
 localparam PARK=0,CPU=1,TEST=2;
 localparam IDLE=0,EXEC=1,ISSUE=2,WAIT_RSP=3,DRAIN=4,SETTLE=5,REPLY=6,RETURN=7;
 reg [2:0] state=IDLE;
 reg [1:0] owner=PARK,code=0;
 reg [431:0] command=0;reg [31:0] cpu_data=0;
 reg [2:0] settle=0;
 wire [3:0] op=command[423:420];
 wire [31:0] address=command[419:388];
 wire [31:0] data=command[387:356];
 wire [3:0] strobe=command[355:352];
 wire healthy=initialized && delay_ready && !fatal;
 wire quiet=telemetry[10] && !telemetry[0];
 // Register status in its originating domain before the three-stage CDC.
 always @(posedge clk_div or posedge rst) begin
  if(rst) parked<=0;
  else parked<=(owner==PARK) && state==IDLE && !mem_valid && quiet && healthy && req_ready;
 end
 assign req_valid=(owner==TEST)?test_valid:(state==ISSUE && healthy);
 assign req_write=(owner==TEST)?test_write:(op==2);
 assign req_addr=(owner==TEST)?test_addr:{address[24:4],3'b000};
 assign req_data=(owner==TEST)?test_data:({96'd0,data} << {address[3:2],5'b00000});
 assign req_mask=(owner==TEST)?test_mask:~({12'd0,strobe} << {address[3:2],2'b00});
 assign test_ready=owner==TEST && req_ready;
 assign test_rsp_valid=owner==TEST && rsp_valid;
 assign test_rsp_data=rsp_data;
 assign test_rsp_status=rsp_status;
 assign rsp_ready=(owner==TEST)?test_rsp_ready:(state==WAIT_RSP);
 always @(posedge clk_div or posedge rst)begin
  if(rst)begin
   owner<=PARK;state<=IDLE;mem_done<=0;mem_response<=0;configuration<=0;
   start<=0;abort_run<=0;tap_load<=0;command<=0;cpu_data<=0;code<=0;settle<=0;
  end else begin
   start<=0;abort_run<=0;tap_load<=0;mem_done<=0;
   case(state)
    IDLE:if(mem_valid)begin command<=mem_data;cpu_data<=0;code<=0;state<=EXEC;end
    EXEC:begin
     state<=REPLY;
     case(op)
      1,2:if(owner!=CPU || !healthy)code<=2;
          else if(op==2 && strobe==0)begin end
          else state<=ISSUE;
      3:if(!healthy || !quiet || command[127:126]==3)code<=2;
          else if(req_ready && !rsp_valid)begin
           owner<=command[127:126];configuration<=command[351:0];
           settle<=3;state<=SETTLE;
          end else state<=EXEC;
      4:if(owner!=TEST || !healthy || !telemetry[11] || !quiet)code<=2;
          else begin configuration<=command[351:0];start<=1;settle<=3;state<=SETTLE;end
      5:if(owner!=TEST)code<=2;
          else begin abort_run<=1;state<=DRAIN;end
      6:begin end
      7:if(owner!=PARK || !healthy || !quiet)code<=2;
          else if(req_ready && !rsp_valid)begin
           configuration<=command[351:0];tap_load<=1;settle<=3;state<=SETTLE;
          end else state<=EXEC;
      default:code<=2;
     endcase
    end
    ISSUE:if(!healthy)begin code<=2;state<=REPLY;end else if(req_ready)state<=WAIT_RSP;
    WAIT_RSP:if(rsp_valid)begin
     cpu_data<=rsp_data[32*address[3:2]+:32];code<=rsp_status==0?0:2;state<=REPLY;
    end
    DRAIN:if(quiet && req_ready && !rsp_valid)state<=REPLY;
    SETTLE:if(settle==0)state<=REPLY;else settle<=settle-1'b1;
    REPLY:begin
     mem_response<={12'd0,owner,code,cpu_data,tap_actual,telemetry};
     mem_done<=1;state<=RETURN;
    end
    RETURN:if(!mem_valid)state<=IDLE;
    default:state<=IDLE;
   endcase
  end
 end
endmodule
