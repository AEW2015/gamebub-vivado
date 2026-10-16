`timescale 1ns/1ps
// Private AXI master for the four-output Clocking Wizard. Entire operation is
// bounded by host-clock time. A fault resets the private IP/bus and fails closed.
module serdes4_clock_sequencer #(parameter integer TIMEOUT=1000000,METER_WINDOW=100000)(
 input wire host_clk,rst,apply,reconfig_safe,input wire [191:0] configuration,
 input wire locked,input wire [31:0] measured_cmd_khz,measured_read_khz,
 input wire cmd_measure_valid,read_measure_valid,
 output wire meter_enable,ip_aresetn,
 output reg busy=0,clock_valid=0,done=0,rejected=0,output reg [7:0] error_code=0,
 output reg [31:0] nominal_hz=0,actual_cmd_khz=0,actual_read_khz=0,epoch=0,
 output reg [191:0] active_configuration=0,
 output reg [10:0] m_axi_awaddr=0,output reg m_axi_awvalid=0,input wire m_axi_awready,
 output reg [31:0] m_axi_wdata=0,output wire [3:0] m_axi_wstrb,output reg m_axi_wvalid=0,input wire m_axi_wready,
 input wire [1:0] m_axi_bresp,input wire m_axi_bvalid,output wire m_axi_bready,
 output reg [10:0] m_axi_araddr=0,output reg m_axi_arvalid=0,input wire m_axi_arready,
 input wire [31:0] m_axi_rdata,input wire [1:0] m_axi_rresp,input wire m_axi_rvalid,output wire m_axi_rready);
 localparam IDLE=0,RESET_IP=1,WAIT_INITIAL=2,WRITE=3,WAIT_B=4,READ=5,WAIT_R=6,WAIT_LOW=7,WAIT_HIGH=8,SETTLE=9,MEASURE=10,FAILED=11,VALIDATE=12;
 reg [3:0] state=IDLE;reg [4:0] index=0;reg readback=0;
 reg ip_reset=0,apply_seen=0;reg [31:0] timer=0;reg [5:0] settle_count=0;
 (* ASYNC_REG="TRUE" *) reg [2:0] lock_sync=0;
 reg [191:0] request_configuration=0;
 reg [1:0] validation_age=0;
 wire [9:0] m8=request_configuration[9:0];wire [2:0] d=request_configuration[34:32],o=request_configuration[66:64];
 wire [31:0] phase=request_configuration[127:96],quarter_phase=request_configuration[159:128];
 wire [31:0] numerator=32'd6250000*m8;
 wire [31:0] khz_numerator=32'd6250*m8;
 wire [5:0] denominator=6'(d)*o;
 // Bound arithmetic widths explicitly. Full-width comparisons below reject
 // out-of-range values before these low-bit arithmetic results can be used.
 reg [21:0] phase_numerator=0,quarter_numerator=0;
 reg [6:0] phase_ticks=0,quarter_ticks=0;
 wire legal=(request_configuration[31:10]==0 && request_configuration[63:35]==0 && request_configuration[95:67]==0 &&
  d>=1 && d<=5 && o>=3 && o<=7 && m8>=96*d && m8<=192*d && m8<=512 &&
  6250*m8>=166000*denominator && 6250*m8<=250000*denominator &&
  phase<=360000 && quarter_phase<=90000 &&
  phase_ticks==quarter_ticks);
 // Restoring division over 32 host cycles, instead of a 32-stage combinational
 // divider in the 100 MHz control path. Runs while the private MMCM resets.
 reg [31:0] dividend=0,quotient=0;
 reg [6:0] remainder=0,divisor=0;reg [5:0] division_steps=0;
 wire [7:0] trial={remainder,dividend[31]};
 wire take=trial>={1'b0,divisor};
 wire [31:0] next_quotient={quotient[30:0],take};
 // Derive the displayed/validated kHz value with a second serial divider in
 // parallel.  This avoids placing a 32-bit constant /1000 divider between
 // nominal_hz and expected_khz on the 100 MHz control path.
 reg [31:0] khz_dividend=0,khz_quotient=0;
 reg [6:0] khz_remainder=0;
 wire [7:0] khz_trial={khz_remainder,khz_dividend[31]};
 wire khz_take=khz_trial>={1'b0,divisor};
 wire [31:0] next_khz_quotient={khz_quotient[30:0],khz_take};
 wire [31:0] am=active_configuration[31:0],ad=active_configuration[63:32],ao=active_configuration[95:64];
 function automatic [31:0] config_word(input [4:0] n);
  begin
   // Explicit address decode avoids synthesizing signed integer /3 and %3
   // operators into the AXI/readback control path.
   case(n)
    // Preserve the v1.3 50-MHz-normalized software profile ABI. The input
    // reference is now 100 MHz, so physical DIVCLK must be twice logical D.
    0:config_word=(ad<<1)|((am/8)<<8)|(((am%8)*125)<<16)|((am%8!=0)?32'h04000000:0);
    2,8,14,17,20:config_word=ao;
    5,11:config_word=4*ao;
    9:config_word=active_configuration[127:96];
    12:config_word=active_configuration[159:128];
    4,7,10,13,16,19,22:config_word=50000;
    23:config_word=3;
    default:config_word=0;
   endcase
  end
 endfunction
 assign ip_aresetn=!rst && !ip_reset;
 assign m_axi_wstrb=15;
 assign m_axi_bready=state==WAIT_B;
 assign m_axi_rready=state==WAIT_R;
 assign meter_enable=state==MEASURE || clock_valid;
 // Rate conversion has its own stage; nominal_hz is stable long before
 // MEASURE, so the comparator never includes the decimal divide path.
 reg [31:0] expected_khz=0;
 localparam integer TOLERANCE_KHZ=3*(400000/METER_WINDOW);
 task automatic fail(input [7:0] code);
  begin
   error_code<=code;clock_valid<=0;busy<=0;done<=1;state<=FAILED;ip_reset<=1;
   division_steps<=0;
   m_axi_awvalid<=0;m_axi_wvalid<=0;m_axi_arvalid<=0;
  end
 endtask
 always @(posedge host_clk)begin
  phase_numerator<=22'(phase[18:0])*o+22'd22500;
  quarter_numerator<=22'(quarter_phase[16:0])*o*4+22'd22500;
  phase_ticks<=7'(phase_numerator/22'd45000);
  quarter_ticks<=7'(quarter_numerator/22'd45000);
  lock_sync<={lock_sync[1:0],locked};apply_seen<=apply;done<=0;rejected<=0;
  if(rst)begin
   state<=IDLE;busy<=0;clock_valid<=0;error_code<=0;timer<=0;ip_reset<=0;
   apply_seen<=0;lock_sync<=0;index<=0;readback<=0;settle_count<=0;
   m_axi_awvalid<=0;m_axi_wvalid<=0;m_axi_arvalid<=0;
   nominal_hz<=0;actual_cmd_khz<=0;actual_read_khz<=0;epoch<=0;active_configuration<=0;
   dividend<=0;quotient<=0;remainder<=0;divisor<=0;division_steps<=0;
   khz_dividend<=0;khz_quotient<=0;khz_remainder<=0;
   request_configuration<=0;validation_age<=0;
   phase_numerator<=0;quarter_numerator<=0;phase_ticks<=0;quarter_ticks<=0;
   expected_khz<=0;
  end else begin
   if(division_steps!=0)begin
   dividend<={dividend[30:0],1'b0};quotient<=next_quotient;
    remainder<=take?7'(trial-{1'b0,divisor}):trial[6:0];
    khz_dividend<={khz_dividend[30:0],1'b0};khz_quotient<=next_khz_quotient;
    khz_remainder<=khz_take?7'(khz_trial-{1'b0,divisor}):khz_trial[6:0];
    division_steps<=division_steps-1'b1;
    if(division_steps==1)begin nominal_hz<=next_quotient;expected_khz<=next_khz_quotient;end
   end
   if(m_axi_awvalid && m_axi_awready)m_axi_awvalid<=0;
   if(m_axi_wvalid && m_axi_wready)m_axi_wvalid<=0;
   if(m_axi_arvalid && m_axi_arready)m_axi_arvalid<=0;
   if(busy)timer<=timer+1'b1;else timer<=0;
   case(state)
    IDLE,FAILED:if(apply && !apply_seen)begin
     if(!reconfig_safe)begin rejected<=1;done<=1;end
     else begin request_configuration<=configuration;validation_age<=0;busy<=1;state<=VALIDATE;end
    end
    VALIDATE:if(validation_age!=2)validation_age<=validation_age+1'b1;
     else if(legal!==1'b1)begin rejected<=1;done<=1;busy<=0;state<=IDLE;end
     else begin
      active_configuration<=request_configuration;nominal_hz<=0;
      dividend<=numerator+denominator/2;divisor<={1'b0,denominator};
      quotient<=0;remainder<=0;division_steps<=32;
      khz_dividend<=khz_numerator+denominator/2;khz_quotient<=0;khz_remainder<=0;
      expected_khz<=0;
      actual_cmd_khz<=0;actual_read_khz<=0;error_code<=0;clock_valid<=0;busy<=1;ip_reset<=1;
      settle_count<=0;index<=0;readback<=0;state<=RESET_IP;
     end
    RESET_IP:if(settle_count==15)begin ip_reset<=0;state<=WAIT_INITIAL;end else settle_count<=settle_count+1'b1;
    WAIT_INITIAL:if(lock_sync[2] && division_steps==0)state<=WRITE;
    WRITE:begin
     m_axi_awaddr<=11'h200+4*index;m_axi_wdata<=config_word(index);
     m_axi_awvalid<=1;m_axi_wvalid<=1;state<=WAIT_B;
    end
    WAIT_B:if(m_axi_bvalid)begin
     if(m_axi_bresp!=0)fail(2);
     else if(index==23)state<=WAIT_LOW;
     else if(index==22)begin index<=0;state<=READ;end
     else begin index<=index+1'b1;state<=WRITE;end
    end
    READ:begin m_axi_araddr<=11'h200+4*index;m_axi_arvalid<=1;state<=WAIT_R;end
    WAIT_R:if(m_axi_rvalid)begin
     if(m_axi_rresp!=0)fail(3);
     else if(m_axi_rdata!==config_word(index))fail(4);
     else if(index==22)begin index<=23;state<=WRITE;end
     else begin index<=index+1'b1;state<=READ;end
    end
    WAIT_LOW:if(!lock_sync[2])state<=WAIT_HIGH;
    WAIT_HIGH:if(lock_sync[2])begin settle_count<=0;state<=SETTLE;end
    SETTLE:if(!lock_sync[2])state<=WAIT_HIGH;
     else if(settle_count==31)state<=MEASURE;else settle_count<=settle_count+1'b1;
    MEASURE:if(cmd_measure_valid && read_measure_valid)begin
     actual_cmd_khz<=measured_cmd_khz;actual_read_khz<=measured_read_khz;
     if(measured_cmd_khz+TOLERANCE_KHZ<expected_khz || measured_cmd_khz>expected_khz+TOLERANCE_KHZ ||
        measured_read_khz+TOLERANCE_KHZ<expected_khz || measured_read_khz>expected_khz+TOLERANCE_KHZ)fail(5);
     else begin clock_valid<=1;busy<=0;done<=1;epoch<=epoch+1'b1;state<=IDLE;end
    end
    default:begin end
   endcase
   if(apply && !apply_seen && busy)rejected<=1;
   if(clock_valid && !lock_sync[2])fail(6);
   if(busy && !reconfig_safe)fail(7);
   else if(busy && timer==TIMEOUT-1)fail(8);
   else if(state==MEASURE && !lock_sync[2])fail(6);
  end
 end
endmodule
