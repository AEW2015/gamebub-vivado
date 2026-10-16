`timescale 1ns/1ps
// Isolated shared-ownership derivative. See BASELINE.json for pinned transport sources.
module s4_shared_stack #(parameter integer POWER_BEATS=15625)(
 input wire clk,clk_div,read_clk,read_clk_div,refclk200,rst,rst_delay,
 input wire mem_valid,input wire [431:0] mem_data,
 output wire mem_done,output wire [1279:0] mem_response,output wire parked,
 output wire initialized,delay_ready,
 output wire [12:0] sdram_a,output wire [1:0] sdram_bs,sdram_cke,sdram_cs_n,
 output wire sdram_ras_n,sdram_cas_n,sdram_we_n,sdram_ldqm,sdram_udqm,sdram_clk,
 inout wire [15:0] sdram_dq);
 wire start,abort_run,tap_load;
 wire [351:0] configuration;
 wire [23:0] cfg_base=configuration[23:0];
 wire [24:0] cfg_count=configuration[56:32];
 wire [8:0] cfg_patterns=configuration[72:64];
 wire [15:0] cfg_seed=configuration[95:80];
 wire [127:0] cfg_settings_tag=configuration[351:224];
 wire [3:0] capture_delay=configuration[101:98];
 wire [1:0] capture_slot=configuration[97:96];
 wire [79:0] tap_value=configuration[207:128];
 wire [79:0] tap_actual;
 wire [1151:0] telemetry;
 wire test_valid,test_write,test_ready,test_rsp_valid,test_rsp_ready;
 wire [23:0] test_addr;wire [127:0] test_data,test_rsp_data;
 wire [15:0] test_mask;wire [2:0] test_rsp_status;
 wire [95:0] tx_ca;wire [63:0] tx_data,raw;wire drive,issue;
 wire [127:0] aligned;wire aligned_valid,aligned_ready,align_fault,align_fault_synced;
 wire req_valid,req_ready,req_write,rsp_valid,rsp_ready,fatal;
 wire [23:0] address;wire [127:0] wdata,rdata;wire [15:0] mask;wire [2:0] rsp_status;
 wire [31:0] refresh_count;
 wire busy,done,passed,failed,invalid,aborted,needs_reset,start_ready,quiescent,reading,first_valid;
 wire [3:0] error_code,active_pattern,patterns_done,first_pattern;
 wire [31:0] progress,total,compared,expected_compares,errors,run_id;
 wire [23:0] run_base,first_addr;wire [24:0] run_count;
 wire [8:0] run_patterns;wire [15:0] run_seed,first_expected,first_actual,dq_errors;
 wire [511:0] bit_counts;wire [127:0] run_tag;
 reg start_seen=0,tap_load_blocked=0;
 reg [3:0] run_capture_delay=3;reg [1:0] run_capture_slot=1;
 wire safe_tap_load=tap_load && quiescent && initialized && !start;
 always @(posedge clk_div)begin
  if(rst)begin start_seen<=0;run_capture_delay<=3;run_capture_slot<=1;tap_load_blocked<=0;end
  else begin
   start_seen<=start;
   if((start && !start_seen && start_ready) || (quiescent && !start))begin
    run_capture_delay<=capture_delay;run_capture_slot<=capture_slot;tap_load_blocked<=0;
   end
   if(tap_load && !safe_tap_load)tap_load_blocked<=1;
  end
 end
 serdes4_test_engine tester(.clk_div(clk_div),.rst(rst),.start(start),.abort_run(abort_run),
  .controller_initialized(initialized),.controller_fatal(fatal),
  .cfg_base(cfg_base),.cfg_count(cfg_count),.cfg_patterns(cfg_patterns),.cfg_seed(cfg_seed),.cfg_settings_tag(cfg_settings_tag),
  .start_ready(start_ready),.quiescent(quiescent),.busy(busy),.done(done),.passed(passed),.failed(failed),
  .invalid(invalid),.aborted(aborted),.needs_reset(needs_reset),.error_code(error_code),.run_id(run_id),
  .completed_work(progress),.total_work(total),.compared_words(compared),.expected_compares(expected_compares),
  .error_words(errors),.active_pattern(active_pattern),.patterns_done(patterns_done),.reading(reading),
  .run_base(run_base),.run_count(run_count),.run_patterns(run_patterns),.run_seed(run_seed),.run_settings_tag(run_tag),
  .first_valid(first_valid),.first_addr(first_addr),.first_expected(first_expected),.first_actual(first_actual),
  .first_pattern(first_pattern),.dq_errors(dq_errors),.dq_error_counts(bit_counts),
  .req_valid(test_valid),.req_write(test_write),.req_addr(test_addr),.req_data(test_data),.req_mask(test_mask),
  .req_ready(test_ready),.rsp_valid(test_rsp_valid),.rsp_ready(test_rsp_ready),.rsp_data(test_rsp_data),.rsp_status(test_rsp_status));
 s4_shared_backend access_control(.clk_div(clk_div),.rst(rst),.mem_valid(mem_valid),.mem_data(mem_data),
  .mem_done(mem_done),.mem_response(mem_response),.initialized(initialized),.delay_ready(delay_ready),.fatal(fatal),
  .telemetry(telemetry),.tap_actual(tap_actual),.configuration(configuration),
  .start(start),.abort_run(abort_run),.tap_load(tap_load),.parked(parked),
  .test_valid(test_valid),.test_write(test_write),.test_addr(test_addr),.test_data(test_data),.test_mask(test_mask),
  .test_ready(test_ready),.test_rsp_valid(test_rsp_valid),.test_rsp_ready(test_rsp_ready),
  .test_rsp_data(test_rsp_data),.test_rsp_status(test_rsp_status),
  .req_valid(req_valid),.req_write(req_write),.req_addr(address),.req_data(wdata),.req_mask(mask),.req_ready(req_ready),
  .rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_data(rdata),.rsp_status(rsp_status));
 serdes4_controller #(.POWER_BEATS(POWER_BEATS)) controller(.clk_div(clk_div),.rst(rst),
  .req_valid(req_valid),.req_ready(req_ready),.req_write(req_write),.req_addr(address),.req_data(wdata),.req_mask(mask),
  .rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_data(rdata),.rsp_status(rsp_status),
  .initialized(initialized),.fatal(fatal),.refresh_count(refresh_count),
  .tx_ca(tx_ca),.tx_data(tx_data),.tx_drive(drive),.read_issue(issue),
  .read_valid(aligned_valid),.read_ready(aligned_ready),.read_data(aligned),.read_fault(align_fault),.read_fault_synced(align_fault_synced));
 serdes4_read_align aligner(.clk_div(clk_div),.read_clk_div(read_clk_div),.rst(rst),
  .issue(issue),.capture_delay(run_capture_delay),.capture_slot(run_capture_slot),.raw(raw),
  .valid(aligned_valid),.ready(aligned_ready),.data(aligned),.fault(align_fault));
 sdram_serdes4_phy #(.RAW_FIFO_ENABLE(0)) phy(.clk(clk),.clk_div(clk_div),.read_clk(read_clk),.read_clk_div(read_clk_div),
  .refclk200(refclk200),.rst_tx(rst),.rst_rx(rst),.rst_delay(rst_delay),
  .tx_ca(tx_ca),.tx_data(tx_data),.tx_drive(drive),.tap_load(safe_tap_load),.tap_value(tap_value),.tap_actual(tap_actual),
  .delay_ready(delay_ready),.rx_store(1'b0),.rx_raw(raw),.rx_ready(1'b0),.rx_valid(),.rx_data(),.rx_overflow(),.rx_fifo_ready(),
  .sdram_a(sdram_a),.sdram_bs(sdram_bs),.sdram_cke(sdram_cke),.sdram_cs_n(sdram_cs_n),
  .sdram_ras_n(sdram_ras_n),.sdram_cas_n(sdram_cas_n),.sdram_we_n(sdram_we_n),
  .sdram_ldqm(sdram_ldqm),.sdram_udqm(sdram_udqm),.sdram_clk(sdram_clk),.sdram_dq(sdram_dq));
 assign telemetry[0*32+:32]={4'h4,patterns_done,active_pattern,error_code,3'd0,reading,start_ready,quiescent,
  align_fault_synced,fatal,initialized,needs_reset,aborted,invalid,failed,passed,done,busy};
 assign telemetry[1*32+:32]=progress;assign telemetry[2*32+:32]=total;
 assign telemetry[3*32+:32]=compared;assign telemetry[4*32+:32]=expected_compares;
 assign telemetry[5*32+:32]=errors;assign telemetry[6*32+:32]=run_id;
 assign telemetry[7*32+:32]={8'd0,run_base};assign telemetry[8*32+:32]={7'd0,run_count};
 assign telemetry[9*32+:32]={run_seed,7'd0,run_patterns};
 assign telemetry[10*32+:32]={8'd0,first_addr};assign telemetry[11*32+:32]={first_expected,first_actual};
 assign telemetry[12*32+:32]={11'd0,first_valid,first_pattern,dq_errors};
 assign telemetry[13*32+:32]=refresh_count;
 assign telemetry[14*32+:32]={24'd0,tap_load_blocked,delay_ready,run_capture_delay,run_capture_slot};
 assign telemetry[15*32+:32]=32'h53543431;
 assign telemetry[16*32+:512]=bit_counts;assign telemetry[32*32+:128]=run_tag;
endmodule
