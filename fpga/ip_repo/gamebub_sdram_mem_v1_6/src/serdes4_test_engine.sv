`timescale 1ns/1ps
// Complete fill, then complete verify for each selected legacy test pattern.
// All ports are in clk_div. Settings must already be coherently transferred
// from the host. settings_tag is metadata, NOT a physical clock measurement.
module serdes4_test_engine #(parameter integer BURST_WORDS=8,WATCHDOG_CYCLES=4096)(
 input wire clk_div,rst,start,abort_run,controller_initialized,controller_fatal,
 input wire [23:0] cfg_base,input wire [24:0] cfg_count,
 input wire [8:0] cfg_patterns,input wire [15:0] cfg_seed,
 input wire [127:0] cfg_settings_tag,
 output wire start_ready,quiescent,
 output reg busy=0,done=0,failed=0,invalid=0,aborted=0,needs_reset=0,
 output wire passed,output reg [3:0] error_code=0,
 output reg [31:0] run_id=0,completed_work=0,total_work=0,
 output reg [31:0] compared_words=0,expected_compares=0,error_words=0,
 output reg [3:0] active_pattern=0,patterns_done=0,output reg reading=0,
 output reg [23:0] run_base=0,output reg [24:0] run_count=0,
 output reg [8:0] run_patterns=0,output reg [15:0] run_seed=0,
 output reg [127:0] run_settings_tag=0,
 output reg first_valid=0,output reg [23:0] first_addr=0,
 output reg [15:0] first_expected=0,first_actual=0,dq_errors=0,
 output reg [3:0] first_pattern=0,output wire [511:0] dq_error_counts,
 output wire req_valid,output wire req_write,output reg [23:0] req_addr=0,
 output reg [127:0] req_data=0,output wire [15:0] req_mask,
 input wire req_ready,rsp_valid,output wire rsp_ready,
 input wire [127:0] rsp_data,input wire [2:0] rsp_status);
 import memory_test_pkg::*;
 localparam integer WD_WIDTH=$clog2(WATCHDOG_CYCLES+1);
 typedef enum logic [3:0] {IDLE,SELECT_PATTERN,PREPARE,BUILD,REQUEST,WAIT_RESPONSE,CHECK_WORD,ADVANCE,FINISH} state_t;
 state_t state=IDLE;
 reg start_d=0,abort_pending=0,last_burst=0;
 reg [24:0] index=0,last_index=0;
 reg [15:0] lfsr=1,next_lfsr=1;
 reg [127:0] actual_packet=0;
 reg [2:0] lane=0;
 reg [WD_WIDTH-1:0] watchdog=0;
 reg [31:0] bit_count[0:15];
 wire [15:0] expected_word=req_data[16*lane+:16];
 wire [15:0] actual_word=actual_packet[16*lane+:16];
 wire [23:0] word_addr=req_addr+24'(lane);
 wire [15:0] mismatch;
 for(genvar b=0;b<16;b++)begin
  // Four-state simulation must fail unknown samples, not skip them. For real
  // binary hardware data this case inequality synthesizes to ordinary XOR.
  assign mismatch[b]=(actual_word[b] !== expected_word[b]);
  assign dq_error_counts[b*32+:32]=bit_count[b];
 end
 function automatic [3:0] pattern_count(input [8:0] mask);
  pattern_count=0;for(integer j=0;j<9;j++)pattern_count=pattern_count+{3'd0,mask[j]};
 endfunction
 assign req_valid=state==REQUEST;
 assign req_write=!reading;
 assign req_mask=16'd0;
 assign rsp_ready=state==WAIT_RESPONSE;
 assign start_ready=state==IDLE && !needs_reset && controller_initialized && !controller_fatal && !rsp_valid;
 // Engine quiescence only: the controller may still be refreshing SDRAM.
 assign quiescent=!busy && !needs_reset;
 assign passed=done && !failed && !invalid && !aborted && !needs_reset &&
  compared_words==expected_compares && completed_work==total_work && total_work!=0;
 initial begin
  if(BURST_WORDS!=4 && BURST_WORDS!=8)$error("Unsupported burst length");
  if(WATCHDOG_CYCLES<2)$error("Watchdog must be at least two cycles");
  for(integer b=0;b<16;b++)bit_count[b]=0;
 end
 always @(posedge clk_div)begin : engine
  reg [15:0] prbs;
  if(rst)begin
   state<=IDLE;start_d<=0;abort_pending<=0;busy<=0;done<=0;failed<=0;
   invalid<=0;aborted<=0;needs_reset<=0;error_code<=0;run_id<=0;
   completed_work<=0;total_work<=0;compared_words<=0;expected_compares<=0;error_words<=0;
   active_pattern<=0;patterns_done<=0;reading<=0;run_base<=0;run_count<=0;
   run_patterns<=0;run_seed<=0;run_settings_tag<=0;
   first_valid<=0;first_addr<=0;first_expected<=0;first_actual<=0;first_pattern<=0;dq_errors<=0;
   index<=0;last_index<=0;last_burst<=0;lfsr<=1;next_lfsr<=1;
   req_addr<=0;req_data<=0;actual_packet<=0;lane<=0;watchdog<=0;
   for(integer b=0;b<16;b++)bit_count[b]<=0;
  end else begin
   start_d<=start;
   if(busy && abort_run)abort_pending<=1;
   if(state==REQUEST || state==WAIT_RESPONSE)watchdog<=watchdog+1'b1;else watchdog<=0;
   case(state)
    IDLE:if(start && !start_d && !needs_reset)begin
     run_id<=run_id+1'b1;done<=0;failed<=0;invalid<=0;aborted<=0;error_code<=0;
     completed_work<=0;total_work<=0;compared_words<=0;expected_compares<=0;error_words<=0;
     first_valid<=0;first_addr<=0;first_expected<=0;first_actual<=0;first_pattern<=0;dq_errors<=0;
     for(integer b=0;b<16;b++)bit_count[b]<=0;
     run_base<=cfg_base;run_count<=cfg_count;run_patterns<=cfg_patterns;
     run_seed<=cfg_seed==0?16'd1:cfg_seed;run_settings_tag<=cfg_settings_tag;
     active_pattern<=0;patterns_done<=0;reading<=0;index<=0;abort_pending<=0;
     if(!start_ready || cfg_count==0 || cfg_patterns==0 ||
        ({2'b0,cfg_base}+{1'b0,cfg_count})>26'h1000000 ||
        (cfg_base & (BURST_WORDS-1))!=0 || (cfg_count & (BURST_WORDS-1))!=0)begin
      invalid<=1;failed<=1;done<=1;error_code<=1;
      if(rsp_valid || controller_fatal)needs_reset<=1;
     end else begin
      busy<=1;last_index<=cfg_count-25'(BURST_WORDS);
      expected_compares<=32'(cfg_count)*32'(pattern_count(cfg_patterns));
      total_work<=32'(cfg_count)*(32'(pattern_count(cfg_patterns))<<1);
      state<=SELECT_PATTERN;
     end
    end
    SELECT_PATTERN:begin
     if(active_pattern==9)state<=FINISH;
     else if(run_patterns[active_pattern])begin
      reading<=0;index<=0;lfsr<=run_seed;state<=PREPARE;
     end else active_pattern<=active_pattern+1'b1;
    end
    PREPARE:begin
     req_addr<=run_base+index[23:0];last_burst<=index==last_index;state<=BUILD;
    end
    BUILD:begin
     prbs=lfsr;
     for(integer j=0;j<8;j++)begin
      if(j<BURST_WORDS)begin
       req_data[j*16+:16]<=pattern_word(active_pattern,{1'b0,req_addr}+25'(j),prbs);
       prbs=lfsr16_next(prbs);
      end else req_data[j*16+:16]<=0;
     end
     next_lfsr<=prbs;state<=REQUEST;watchdog<=0;
    end
    REQUEST:if(req_ready)begin state<=WAIT_RESPONSE;watchdog<=0;end
    WAIT_RESPONSE:if(rsp_valid)begin
     watchdog<=0;
     if(rsp_status!=0)begin failed<=1;error_code<=4;needs_reset<=1;busy<=0;done<=1;state<=IDLE;end
     else if(reading)begin actual_packet<=rsp_data;lane<=0;state<=CHECK_WORD;end
     else begin completed_work<=completed_work+32'(BURST_WORDS);state<=ADVANCE;end
    end
    CHECK_WORD:begin
     completed_work<=completed_work+1'b1;compared_words<=compared_words+1'b1;
     if(mismatch!=0)begin
      failed<=1;if(error_code==0)error_code<=8;
      if(error_words!=32'hffffffff)error_words<=error_words+1'b1;
      dq_errors<=dq_errors|mismatch;
      for(integer b=0;b<16;b++)if(mismatch[b] && bit_count[b]!=32'hffffffff)bit_count[b]<=bit_count[b]+1'b1;
      if(!first_valid)begin
       first_valid<=1;first_addr<=word_addr;first_expected<=expected_word;first_actual<=actual_word;first_pattern<=active_pattern;
      end
     end
     if(lane==BURST_WORDS-1)state<=ADVANCE;else lane<=lane+1'b1;
    end
    ADVANCE:begin
     lfsr<=next_lfsr;
     if(last_burst)begin
      if(reading)begin patterns_done<=patterns_done+1'b1;active_pattern<=active_pattern+1'b1;state<=SELECT_PATTERN;end
      else begin reading<=1;index<=0;lfsr<=run_seed;state<=PREPARE;end
     end else begin index<=index+25'(BURST_WORDS);state<=PREPARE;end
    end
    FINISH:begin busy<=0;done<=1;state<=IDLE;end
    default:begin failed<=1;needs_reset<=1;error_code<=7;busy<=0;done<=1;state<=IDLE;end
   endcase
   // A stop drains a presented/accepted transaction before ending the run.
   if(busy && (abort_pending || abort_run) &&
      (state==SELECT_PATTERN || state==PREPARE || state==BUILD || state==ADVANCE || state==FINISH))begin
    busy<=0;done<=1;failed<=1;aborted<=1;error_code<=6;state<=IDLE;
   end
   if(busy && controller_fatal)begin
    busy<=0;done<=1;failed<=1;needs_reset<=1;error_code<=5;state<=IDLE;
   end else if(watchdog==WATCHDOG_CYCLES-1 &&
      ((state==REQUEST && !req_ready) || (state==WAIT_RESPONSE && !rsp_valid)))begin
    busy<=0;done<=1;failed<=1;needs_reset<=1;
    error_code<=state==REQUEST?4'd2:4'd3;state<=IDLE;
   end
  end
 end
endmodule
