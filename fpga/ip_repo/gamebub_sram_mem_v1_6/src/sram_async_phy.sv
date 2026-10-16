`timescale 1ns/1ps
// 100 MHz scheduler / 400 MHz DDR I/O. Timing bytes count 1.25 ns slots.
// DQ ownership has whole-word guards; data value and byte enables use fine slots.
module sram_async_phy(
 input wire clk,io_clk,rst_n,input wire req_valid,output wire req_ready,input wire req_write,input wire [17:0] req_addr,input wire [15:0] req_data,input wire [1:0] req_be,
 output reg rsp_valid,input wire rsp_ready,output reg [15:0] rsp_data,
 input wire [7:0] read_wait,write_setup,write_width,write_hold,release_wait,address_setup,
 output wire idle,output wire [3:0] debug_state,
 output wire [17:0] sram_a,inout wire [15:0] sram_io,output wire sram_ce_n,sram_oe_n,sram_we_n,sram_ub_n,sram_lb_n);
 localparam IDLE=0,SUM1=1,SUM2=2,SUM3=3,SUM4=4,RUN=5,DRAIN=6,RESP=7,WARM=8;
 reg [3:0] state,drain_count;
 (* IOB="TRUE" *) reg ce_guard_n;
 assign sram_ce_n=ce_guard_n;
 reg writing;reg [1:0] lanes,drive;
 reg [17:0] address,last_address;reg [15:0] data;
 reg [7:0] rd,ws,ww,wh,rel,ad;
 reg [11:0] access_start,we_start,we_end,read_end,bus_end,finish_slot,slot_base;
 reg [7:0] ce_word,oe_word,we_word,ub_word,lb_word,capture_mask;
 reg [7:0] capture_pipe[0:3];
 wire [127:0] samples;reg [127:0] previous_samples;
 wire [17:0] output_address=state==RUN?address:last_address;
 reg [127:0] data_words;
 integer k,b;reg [11:0] slot;
 assign idle=state==IDLE;assign req_ready=idle && rst_n;assign debug_state=state;
 always @* begin
  ce_word=8'hff;oe_word=8'hff;we_word=8'hff;ub_word=8'hff;lb_word=8'hff;capture_mask=0;data_words=0;slot=0;
  for(integer n=0;n<8;n=n+1)begin
   slot=slot_base+n;
   if(state==RUN)begin
    if(lanes!=0 && slot>=access_start && slot<bus_end)begin
     ce_word[n]=0;ub_word[n]=!lanes[1];lb_word[n]=!lanes[0];
     if(writing)for(integer bit_n=0;bit_n<16;bit_n=bit_n+1)data_words[bit_n*8+n]=data[bit_n];
    end
    if(!writing && lanes!=0 && rd!=0 && slot>=access_start && slot<read_end)oe_word[n]=0;
    if(writing && lanes!=0 && ww!=0 && slot>=we_start && slot<we_end)we_word[n]=0;
    if(!writing && slot==read_end)capture_mask[n]=1;
   end
  end
 end
 wire [3:0] serial_control;
 assign {sram_oe_n,sram_we_n,sram_ub_n,sram_lb_n}=serial_control;
 sram_serdes_out #(.INIT(1'b1)) oe_tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word(oe_word),.tristate(1'b0),.serial(serial_control[3]));
 sram_serdes_out #(.INIT(1'b1)) we_tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word(we_word),.tristate(1'b0),.serial(serial_control[2]));
 sram_serdes_out #(.INIT(1'b1)) ub_tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word(ub_word),.tristate(1'b0),.serial(serial_control[1]));
 sram_serdes_out #(.INIT(1'b1)) lb_tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word(lb_word),.tristate(1'b0),.serial(serial_control[0]));
 genvar g;
 generate
  for(g=0;g<18;g=g+1)begin:address_io
   sram_serdes_out tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word({8{output_address[g]}}),.tristate(1'b0),.serial(sram_a[g]));
  end
  for(g=0;g<16;g=g+1)begin:data_io
   wire q,t,d;
   sram_serdes_out tx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.word(data_words[g*8+:8]),.tristate(!drive[g/8]),.serial(q),.tri_out(t));
   IOBUF pad(.I(q),.O(d),.T(t),.IO(sram_io[g]));
   sram_serdes_in rx(.clk(clk),.io_clk(io_clk),.rst_n(rst_n),.serial(d),.samples(samples[g*8+:8]));
  end
 endgenerate
 // NETWORKING DDR samples straddle CLKDIV by four slots. Align adjacent
 // captures to an output word. Output-word-to-consumer latency is four CLKDIVs.
 reg [7:0] aligned;
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
   state<=WARM;ce_guard_n<=1;drain_count<=0;writing<=0;lanes<=0;drive<=0;address<=0;last_address<=0;data<=0;
   rd<=0;ws<=0;ww<=0;wh<=0;rel<=0;ad<=0;access_start<=0;we_start<=0;we_end<=0;read_end<=0;bus_end<=0;finish_slot<=0;slot_base<=0;
   rsp_valid<=0;rsp_data<=0;previous_samples<=0;aligned=0;
   for(k=0;k<4;k=k+1)capture_pipe[k]<=0;
  end else begin
   previous_samples<=samples;
   capture_pipe[0]<=capture_mask;for(k=1;k<4;k=k+1)capture_pipe[k]<=capture_pipe[k-1];
   for(b=0;b<16;b=b+1)begin
    aligned={samples[b*8+:4],previous_samples[b*8+4+:4]};
    for(k=0;k<8;k=k+1)if(capture_pipe[3][k])rsp_data[b]<=lanes[b/8]?aligned[k]:1'b0;
   end
   case(state)
    IDLE:if(req_valid)begin
     address<=req_addr;data<=req_data;writing<=req_write;lanes<=req_be;
     rd<=read_wait;ws<=write_setup;ww<=write_width;wh<=write_hold;rel<=release_wait;ad<=address_setup;
     rsp_data<=0;state<=SUM1;
    end
    SUM1:begin access_start<={4'd0,ad};we_start<={4'd0,ad}+{4'd0,ws};drive<=writing?lanes:2'd0;state<=SUM2;end
    SUM2:begin we_end<=we_start+{4'd0,ww};read_end<=access_start+{4'd0,rd};state<=SUM3;end
    SUM3:begin bus_end<=writing?we_end+{4'd0,wh}:read_end;state<=SUM4;end
    SUM4:begin ce_guard_n<=lanes==0;finish_slot<=bus_end+{4'd0,rel};slot_base<=0;state<=RUN;end
    RUN:begin
     slot_base<=slot_base+12'd8;
     if(slot_base>=finish_slot)begin last_address<=address;drain_count<=0;state<=DRAIN;end
    end
    DRAIN:begin
     drain_count<=drain_count+1'b1;
     if(drain_count==7)begin ce_guard_n<=1;drive<=0;rsp_valid<=1;state<=RESP;end
    end
    WARM:begin drain_count<=drain_count+1'b1;if(drain_count==7)state<=IDLE;end
    RESP:if(rsp_ready)begin rsp_valid<=0;state<=IDLE;end
    default:begin drive<=0;state<=IDLE;rsp_valid<=0;end
   endcase
  end
 end
endmodule


