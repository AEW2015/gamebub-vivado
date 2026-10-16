module sram_shared_tester #(parameter integer CLOCK_HZ=50000000,DEFAULT_TEST_WORDS=4096)(
 input wire clk,rst_n,clock_ready,clock_fault,test_grant,
 output reg [47:0] normal_timings,
 output wire test_request,output wire [47:0] timings,
 output wire req_valid,input wire req_ready,output wire req_write,output wire [17:0] req_addr,output wire [15:0] req_data,output wire [1:0] req_be,
 input wire rsp_valid,output wire rsp_ready,input wire [15:0] rsp_data,input wire rsp_error,
 input wire [11:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,
 output wire [1:0] s_axi_bresp,output wire s_axi_bvalid,input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,
 output wire [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output wire s_axi_rvalid,input wire s_axi_rready);
 wire clock_busy=!clock_ready;wire [2:0] clock_selected=0;
 wire [6:0] command;wire [255:0] requested;reg [255:0] active;
 reg profile_pending,profile_restore,profile_passed;
 reg [31:0] observed_passes,run_failures;
 reg armed,applying,restart,clear;wire super_fault=0;wire engine_fault,engine_quiet,busy;
 wire quiescent=!profile_pending && engine_quiet && !test_grant && !rsp_valid;
 wire fault=super_fault || engine_fault || clock_fault;
 reg [31:0] epoch;wire [31:0] work,total_work,passes,completed,aborts,failures,reads,writes,first_epoch;
 wire [63:0] active_cycles,payload_bytes;
 wire first_valid;wire [17:0] first_addr,cursor;wire [15:0] first_expected,first_actual;
 wire [7:0] first_stage,stage;wire [511:0] dq_errors;wire [3:0] engine_state,phy_state;
 reg [63:0] elapsed_cycles;
 always @(posedge clk)if(!rst_n)elapsed_cycles<=0;else elapsed_cycles<=elapsed_cycles+1'b1;
 wire [2047:0] status;
 assign status[0*32+:32]={12'd0,phy_state,engine_state,stage,fault,applying,!quiescent,armed};
 assign status[1*32+:32]=epoch;
 assign status[2*32+:32]=work;assign status[3*32+:32]=total_work;
 assign status[4*32+:32]=passes;assign status[5*32+:32]=completed;assign status[6*32+:32]=aborts;
 assign status[7*32+:32]=failures;assign status[8*32+:32]={13'd0,first_valid,first_addr};
 assign status[9*32+:32]={first_actual,first_expected};assign status[10*32+:32]=first_epoch;
 assign status[11*32+:32]={24'd0,first_stage};
 assign status[12*32+:64]=active_cycles;assign status[14*32+:64]=payload_bytes;
 assign status[16*32+:64]=elapsed_cycles;
 assign status[18*32+:32]=reads;assign status[19*32+:32]=writes;
 assign status[20*32+:32]={14'd0,cursor};assign status[21*32+:32]=CLOCK_HZ;
 assign status[22*32+:256]=active;
 wire [31:0] memory_hz=100000000;
 assign status[30*32+:32]=clock_ready?memory_hz:0;
 assign status[31*32+:32]={24'd0,clock_selected,2'd0,clock_fault,clock_busy,clock_ready};
 assign phy_state=0; // PHY phase is intentionally not sampled as an incoherent bus.
 assign status[32*32+:512]=dq_errors;
 assign status[48*32+:32]={29'd0,clock_ready,test_grant,test_request};
 assign status[49*32+:32]=normal_timings[31:0];
 assign status[50*32+:32]={16'd0,normal_timings[47:32]};
 assign status[51*32+:32]={29'd0,(normal_timings!=48'h202020202040),profile_pending,profile_passed};
 assign status[52*32+:384]=0;
 sram_shared_test_regs #(.DEFAULT_TEST_WORDS(DEFAULT_TEST_WORDS)) regs(.*);
 reg [255:0] captured;
 assign test_request=profile_pending || armed || !engine_quiet || rsp_valid;
 assign timings=active[96+:48];
 always @(posedge clk)begin
  if(!rst_n)begin
   armed<=0;applying<=0;restart<=0;clear<=0;epoch<=0;captured<=0;
   normal_timings<=48'h202020202040;profile_pending<=0;profile_restore<=0;profile_passed<=0;observed_passes<=0;run_failures<=0;
   active<={32'd0,32'd0,32'd0,32'h00002020,32'h20202040,32'h1d0f0008,32'(DEFAULT_TEST_WORDS),32'd0};
  end else begin
   restart<=0;clear<=0;
   observed_passes<=passes;
   if(passes>observed_passes && failures==run_failures && !fault)profile_passed<=1;
   if(failures!=run_failures || fault || command[0] || command[2] || command[3])profile_passed<=0;
   if(command[0])run_failures<=failures;
   // Acquire the same exclusive grant as testing. This drains BOTH halves of
   // accepted CPU words and their AXI responses before changing CPU timing.
   if(command[5] || command[6])begin profile_pending<=1;profile_restore<=command[6];end
   if(profile_pending && test_grant && engine_quiet && !rsp_valid)begin
    normal_timings<=profile_restore?48'h202020202040:active[96+:48];
    profile_pending<=0;
   end
   if(engine_fault || clock_fault || (rsp_valid && rsp_error))armed<=0;
   // Every new start restarts the pass: CPU use may have changed SRAM while paused.
   if(command[0] && !fault && !applying)begin armed<=1;restart<=1;end
   if(command[1])armed<=0;
   if(command[3] && !armed && !applying && quiescent)clear<=1;
   if(command[2] && !applying)begin captured<=requested;applying<=1;armed<=0;end
   if(applying && quiescent)begin
    active<=captured;epoch<=epoch+1'b1;restart<=1;applying<=0;
   end
  end
 end
 sram_test_engine #(.CLOCK_HZ(CLOCK_HZ)) engine(.clk(clk),.rst_n(rst_n),.run(armed && test_grant && !applying && !fault && clock_ready),.abort(clock_fault || (rsp_valid && rsp_error)),.restart(restart),.clear(clear),
 .base(active[17:0]),.count(active[32+:19]),.pattern(active[64+:4]),.mode(active[68+:3]),.descending(active[72]),.stop_on_error(active[73]),.seed(active[80+:16]),.dwell_ms(active[160+:32]),.epoch(epoch),
 .quiescent(engine_quiet),.busy(busy),.fault(engine_fault),.req_valid(req_valid),.req_ready(req_ready),.req_write(req_write),.req_addr(req_addr),.req_data(req_data),.req_be(req_be),
 .rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_data(rsp_data),.work(work),.total_work(total_work),.passes(passes),.completed(completed),.aborts(aborts),.failures(failures),.reads(reads),.writes(writes),
 .active_cycles(active_cycles),.payload_bytes(payload_bytes),.first_valid(first_valid),.first_addr(first_addr),.first_expected(first_expected),.first_actual(first_actual),.first_epoch(first_epoch),.first_stage(first_stage),.dq_errors(dq_errors),.stage(stage),.cursor(cursor),.debug_state(engine_state));
endmodule
