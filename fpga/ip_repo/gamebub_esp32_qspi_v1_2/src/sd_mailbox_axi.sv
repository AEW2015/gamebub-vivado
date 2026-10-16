// SD Explorer mailbox: AXI (50 MHz) <-> ESP QSPI service (200 MHz).
// Payload RAM is genuinely dual-clock; ownership changes only at commit.
module sd_mailbox_axi(
 input wire s_axi_aclk,input wire s_axi_aresetn,input wire [13:0] s_axi_awaddr,input wire s_axi_awvalid,output wire s_axi_awready,input wire [31:0] s_axi_wdata,input wire [3:0] s_axi_wstrb,input wire s_axi_wvalid,output wire s_axi_wready,output wire [1:0] s_axi_bresp,output reg s_axi_bvalid,input wire s_axi_bready,input wire [13:0] s_axi_araddr,input wire s_axi_arvalid,output wire s_axi_arready,output reg [31:0] s_axi_rdata,output wire [1:0] s_axi_rresp,output reg s_axi_rvalid,input wire s_axi_rready,
 input wire qspi_clk,input wire qspi_rst_n,input wire qspi_wr,input wire [13:0] qspi_addr,input wire [31:0] qspi_wdata,output reg [31:0] qspi_rdata);
 localparam MAGIC=32'h47424d58, ABI=32'h00010000;
 reg aw_hold; reg [13:0] awaddr_hold; reg read_pending,read_reqmem,read_rspmem; reg [13:0] read_addr; reg [31:0] req_seq,req_opcode,req_length,req_commit,rsp_ack;
 reg [31:0] session=1;reg reset_seen=1;
 reg [31:0] rsp_seq_q,rsp_status_q,rsp_length_q,rsp_commit_q;
 // Commit crossings are synchronized.  Their associated fields are bundled
 // data, held stable by the producer until the consumer acknowledges commit.
 (* ASYNC_REG="TRUE" *) reg [31:0] rsp_commit_m1,rsp_commit_m2;
 (* ASYNC_REG="TRUE" *) reg [31:0] req_commit_q1,req_commit_q2,rsp_ack_q1,rsp_ack_q2,session_q1,session_q2;
 wire req_cpu_en=aw_hold&&s_axi_wvalid&&s_axi_wready&&(awaddr_hold>=14'h0100&&awaddr_hold<14'h1100);
 wire req_cpu_rd=s_axi_arvalid&&s_axi_arready&&(s_axi_araddr>=14'h0100&&s_axi_araddr<14'h1100);
 wire rsp_cpu_rd=s_axi_arvalid&&s_axi_arready&&(s_axi_araddr>=14'h1100&&s_axi_araddr<14'h2100);
 wire rsp_q_en=qspi_wr&&(qspi_addr>=14'h1100&&qspi_addr<14'h2100);
 wire req_q_rd=!qspi_wr&&(qspi_addr>=14'h0100&&qspi_addr<14'h1100);
 wire [31:0] req_cpu_dout,rsp_cpu_dout,req_q_dout,rsp_q_dout;
 xpm_memory_tdpram #(.ADDR_WIDTH_A(10),.ADDR_WIDTH_B(10),.AUTO_SLEEP_TIME(0),.BYTE_WRITE_WIDTH_A(32),.BYTE_WRITE_WIDTH_B(32),.CLOCKING_MODE("independent_clock"),.MEMORY_INIT_FILE("none"),.MEMORY_INIT_PARAM("0"),.MEMORY_OPTIMIZATION("true"),.MEMORY_PRIMITIVE("block"),.MEMORY_SIZE(32768),.READ_DATA_WIDTH_A(32),.READ_DATA_WIDTH_B(32),.READ_LATENCY_A(1),.READ_LATENCY_B(1),.WRITE_DATA_WIDTH_A(32),.WRITE_DATA_WIDTH_B(32),.WRITE_MODE_A("read_first"),.WRITE_MODE_B("read_first")) req_ram(.clka(s_axi_aclk),.ena(req_cpu_en|req_cpu_rd),.wea(req_cpu_en),.addra(aw_hold?awaddr_hold[11:2]:s_axi_araddr[11:2]),.dina(s_axi_wdata),.douta(req_cpu_dout),.clkb(qspi_clk),.enb(req_q_rd),.web(1'b0),.addrb(qspi_addr[11:2]),.dinb(0),.doutb(req_q_dout),.rsta(!s_axi_aresetn),.rstb(!qspi_rst_n),.regcea(1'b1),.regceb(1'b1),.sleep(1'b0));
 xpm_memory_tdpram #(.ADDR_WIDTH_A(10),.ADDR_WIDTH_B(10),.AUTO_SLEEP_TIME(0),.BYTE_WRITE_WIDTH_A(32),.BYTE_WRITE_WIDTH_B(32),.CLOCKING_MODE("independent_clock"),.MEMORY_INIT_FILE("none"),.MEMORY_INIT_PARAM("0"),.MEMORY_OPTIMIZATION("true"),.MEMORY_PRIMITIVE("block"),.MEMORY_SIZE(32768),.READ_DATA_WIDTH_A(32),.READ_DATA_WIDTH_B(32),.READ_LATENCY_A(1),.READ_LATENCY_B(1),.WRITE_DATA_WIDTH_A(32),.WRITE_DATA_WIDTH_B(32),.WRITE_MODE_A("read_first"),.WRITE_MODE_B("read_first")) rsp_ram(.clka(s_axi_aclk),.ena(rsp_cpu_rd),.wea(1'b0),.addra(s_axi_araddr[11:2]),.dina(0),.douta(rsp_cpu_dout),.clkb(qspi_clk),.enb(rsp_q_en),.web(rsp_q_en),.addrb(qspi_addr[11:2]),.dinb(qspi_wdata),.doutb(rsp_q_dout),.rsta(!s_axi_aresetn),.rstb(!qspi_rst_n),.regcea(1'b1),.regceb(1'b1),.sleep(1'b0));
 assign s_axi_awready=!aw_hold&&!s_axi_bvalid;assign s_axi_wready=aw_hold&&!s_axi_bvalid;assign s_axi_arready=!s_axi_rvalid&&!read_pending;assign s_axi_bresp=0;assign s_axi_rresp=0;
 always @(posedge s_axi_aclk)begin
  if(!s_axi_aresetn)begin reset_seen<=1;aw_hold<=0;s_axi_bvalid<=0;s_axi_rvalid<=0;read_pending<=0;read_reqmem<=0;read_rspmem<=0;read_addr<=0;req_seq<=0;req_opcode<=0;req_length<=0;req_commit<=0;rsp_ack<=0;rsp_commit_m1<=0;rsp_commit_m2<=0;end else begin
   if(reset_seen)begin session<=session+1'b1;reset_seen<=0;end
   rsp_commit_m1<=rsp_commit_q;rsp_commit_m2<=rsp_commit_m1;
   if(s_axi_awvalid&&s_axi_awready)begin aw_hold<=1;awaddr_hold<=s_axi_awaddr;end
   if(aw_hold&&s_axi_wvalid&&s_axi_wready)begin aw_hold<=0;s_axi_bvalid<=1;case(awaddr_hold[7:2])4:req_seq<=s_axi_wdata;5:req_opcode<=s_axi_wdata;6:req_length<=s_axi_wdata;7:req_commit<=s_axi_wdata;12:rsp_ack<=s_axi_wdata;default:;endcase end
   if(s_axi_bvalid&&s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_arvalid&&s_axi_arready)begin read_pending<=1;read_reqmem<=s_axi_araddr>=14'h0100&&s_axi_araddr<14'h1100;read_rspmem<=s_axi_araddr>=14'h1100&&s_axi_araddr<14'h2100;read_addr<=s_axi_araddr;end
   if(read_pending)begin read_pending<=0;s_axi_rvalid<=1;if(read_reqmem)s_axi_rdata<=req_cpu_dout;else if(read_rspmem)s_axi_rdata<=rsp_cpu_dout;else case(read_addr[7:2])0:s_axi_rdata<=MAGIC;1:s_axi_rdata<=ABI;2:s_axi_rdata<=32'h00000007;3:s_axi_rdata<=session;4:s_axi_rdata<=req_seq;5:s_axi_rdata<=req_opcode;6:s_axi_rdata<=req_length;7:s_axi_rdata<=req_commit;8:s_axi_rdata<=rsp_seq_q;9:s_axi_rdata<=rsp_status_q;10:s_axi_rdata<=rsp_length_q;11:s_axi_rdata<=rsp_commit_m2;12:s_axi_rdata<=rsp_ack;default:s_axi_rdata<=0;endcase end
   if(s_axi_rvalid&&s_axi_rready)s_axi_rvalid<=0;
  end end
 always @(posedge qspi_clk)begin if(!qspi_rst_n)begin rsp_seq_q<=0;rsp_status_q<=0;rsp_length_q<=0;rsp_commit_q<=0;req_commit_q1<=0;req_commit_q2<=0;rsp_ack_q1<=0;rsp_ack_q2<=0;session_q1<=0;session_q2<=0;end else begin req_commit_q1<=req_commit;req_commit_q2<=req_commit_q1;rsp_ack_q1<=rsp_ack;rsp_ack_q2<=rsp_ack_q1;session_q1<=session;session_q2<=session_q1;if(qspi_wr)case(qspi_addr[7:2])8:rsp_seq_q<=qspi_wdata;9:rsp_status_q<=qspi_wdata;10:rsp_length_q<=qspi_wdata;11:rsp_commit_q<=qspi_wdata;default:;endcase end end
 always @* begin if(req_q_rd)qspi_rdata=req_q_dout;else if(!qspi_wr&&(qspi_addr>=14'h1100&&qspi_addr<14'h2100))qspi_rdata=rsp_q_dout;else case(qspi_addr[7:2])0:qspi_rdata=MAGIC;1:qspi_rdata=ABI;2:qspi_rdata=32'h00000007;3:qspi_rdata=session_q2;4:qspi_rdata=req_seq;5:qspi_rdata=req_opcode;6:qspi_rdata=req_length;7:qspi_rdata=req_commit_q2;8:qspi_rdata=rsp_seq_q;9:qspi_rdata=rsp_status_q;10:qspi_rdata=rsp_length_q;11:qspi_rdata=rsp_commit_q;12:qspi_rdata=rsp_ack_q2;default:qspi_rdata=0;endcase end
endmodule
