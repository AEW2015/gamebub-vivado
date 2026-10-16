`timescale 1ns/1ps
// v1.5: pipelined AXI reads in one always-on 200 MHz domain.
// Use AXI Clock Converter upstream
// if the processor bus uses a different clock. No CPU access gates QSPI.
module gamebub_esp32_v102 #(
 parameter integer C_MANUAL_OVERRIDE=0,
 parameter integer C_ENABLE_OVERLAY_AXIS=0,
 parameter integer C_OVERLAY_MONOCHROME=1,
 parameter integer C_ENABLE_CPU_OVERLAY=0
)(
 input wire service_clk, service_resetn,
 input wire qspi_sck,qspi_cs_n,
 inout wire [3:0] qspi_dq,
 input wire [11:0] buttons_n,
 output wire irq_gate, cpu_irq,
 input wire [11:0] s_axi_awaddr,
 input wire [2:0] s_axi_awprot,
 input wire s_axi_awvalid, output wire s_axi_awready,
 input wire [31:0] s_axi_wdata,
 input wire [3:0] s_axi_wstrb,
 input wire s_axi_wvalid, output wire s_axi_wready,
 output reg [1:0] s_axi_bresp,
 output reg s_axi_bvalid, input wire s_axi_bready,
 input wire [11:0] s_axi_araddr,
 input wire [2:0] s_axi_arprot,
 input wire s_axi_arvalid, output wire s_axi_arready,
 output reg [31:0] s_axi_rdata,
 output reg [1:0] s_axi_rresp,
 output reg s_axi_rvalid, input wire s_axi_rready,
 input wire overlay_clk,overlay_resetn,
 output wire [31:0] M_AXIS_OVERLAY_tdata,
 output wire M_AXIS_OVERLAY_tvalid,M_AXIS_OVERLAY_tuser,M_AXIS_OVERLAY_tlast,
 input wire M_AXIS_OVERLAY_tready,
 output wire ov_wr,output wire [17:0] ov_addr,output wire [15:0] ov_data
);
 wire irq_request;
 reg gate_manual;
 (* ASYNC_REG="TRUE" *) reg [1:0] gate_sync;
 wire gate_asserted=service_resetn && (gate_sync[1] || (C_MANUAL_OVERRIDE && gate_manual));
 // Rev4 nFET gate HIGH asserts the shared ESP32 active-LOW IRQ.
 OBUF irq_driver(.I(gate_asserted),.O(irq_gate));
 always @(posedge service_clk or negedge service_resetn) begin
  if(!service_resetn) gate_sync<=0;
  else gate_sync<={gate_sync[0],irq_request};
 end
 wire [3:0] di,dout,oe;
 genvar k;
 generate for(k=0;k<4;k=k+1) begin: io
  IOBUF dq_buffer(.I(dout[k]),.O(di[k]),.T(!oe[k]),.IO(qspi_dq[k]));
 end endgenerate
 reg [31:0] diagnostic_control;
 wire [31:0] diagnostic_data;
 wire bank_read=s_axi_araddr>=12'h100 && s_axi_araddr<12'h140;
 // One outstanding read. Separate address/selector capture, data selection,
 // and response stages: no live ARADDR -> endpoint mux -> AXI RDATA path.
 // Status/counters are sampled in the data stage, not atomically at AR.
 reg [1:0] read_stage;
 reg [11:0] read_addr;
 reg [4:0] selector;
 reg read_diag;
 reg [31:0] read_base_data,read_diag_data;
 reg [1:0] read_response;
 reg aw_full,w_full;
 reg [11:0] aw_addr;
 reg [31:0] w_data;
 reg [3:0] w_strb;
 wire commit=aw_full && w_full && !s_axi_bvalid;
 reg cpu_overlay_enable=0;
 reg [12:0] cpu_word_index=0;
 reg [16:0] cpu_pixel_index=0;
 reg [31:0] cpu_pixel_writes=0;
 reg [31:0] cpu_word_writes=0,cpu_last_word=0;
 wire cpu_packed_write=commit && C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS &&
                aw_addr==12'h208 && cpu_word_index<5760 && (|w_strb);
 wire cpu_single_write=commit && C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS &&
                aw_addr==12'h228 && cpu_pixel_index<92160 && w_strb[0];
 wire [15:0] cpu_pixel_mask=cpu_single_write?(16'b1<<cpu_pixel_index[3:0]):
                {{4{w_strb[3]}},{4{w_strb[2]}},{4{w_strb[1]}},{4{w_strb[0]}}};
 esp32_v102_endpoint endpoint(
  .clk200(service_clk),.rst_n(service_resetn),.qspi_sck(qspi_sck),.qspi_cs_n(qspi_cs_n),
  .qspi_dq_i(di),.dq_o(dout),.dq_oe(oe),.buttons_native(~buttons_n),.vblank(1'b0),
  .irq_request(irq_request),.mailbox_rdata(32'b0),
  .diag_select(selector),.inject_toggle(diagnostic_control[8]),.diag_data(diagnostic_data),
  .ov_wr(ov_wr),.ov_addr(ov_addr),.ov_data(ov_data)
 );
 generate if(C_ENABLE_OVERLAY_AXIS) begin: overlay_axis_enabled
  esp32_overlay_axis #(.MONOCHROME(C_OVERLAY_MONOCHROME),.CPU_OVERLAY(C_ENABLE_CPU_OVERLAY)) overlay_stream(
   .service_clk(service_clk),.service_resetn(service_resetn),
   .ov_wr(ov_wr),.ov_addr(ov_addr),.ov_data(ov_data),
   .cpu_enable(cpu_overlay_enable),.cpu_write(cpu_packed_write || cpu_single_write),
   .cpu_word_address(cpu_single_write?cpu_pixel_index[16:4]:cpu_word_index),
   .cpu_word_data(cpu_single_write?{16{w_data[1:0]}}:w_data),.cpu_pixel_strobe(cpu_pixel_mask),
   .axis_clk(overlay_clk),.axis_resetn(overlay_resetn),
   .tdata(M_AXIS_OVERLAY_tdata),.tvalid(M_AXIS_OVERLAY_tvalid),
   .tuser(M_AXIS_OVERLAY_tuser),.tlast(M_AXIS_OVERLAY_tlast),.tready(M_AXIS_OVERLAY_tready));
 end else begin: overlay_axis_disabled
  assign M_AXIS_OVERLAY_tdata=0;
  assign M_AXIS_OVERLAY_tvalid=0;
  assign M_AXIS_OVERLAY_tuser=0;
  assign M_AXIS_OVERLAY_tlast=0;
 end endgenerate
 // Separate CPU event ownership: ESP32 W1C never acknowledges this latch.
 (* ASYNC_REG="TRUE" *) reg [11:0] buttons_meta,buttons_sync;
 reg [11:0] buttons_previous;
 wire button_change=buttons_sync!=buttons_previous;
 wire [11:0] host_buttons;
 generate for(k=0;k<12;k=k+1) begin: host_map
  assign host_buttons[11-k]=buttons_sync[k];
 end endgenerate
 reg cpu_pending,cpu_enable;
 // Register before crossing to a different processor clock. The destination
 // still needs a level synchronizer (e.g. AXI INTC asynchronous-input mode).
 // MMIO pending/enable semantics are unchanged; IRQ has one service-clock delay.
 reg cpu_irq_registered=0;
 always @(posedge service_clk) begin
  if(!service_resetn) cpu_irq_registered<=0;
  else cpu_irq_registered<=cpu_pending & cpu_enable;
 end
 assign cpu_irq=cpu_irq_registered;
 // Independent AW/W holding registers; one outstanding write response.
 assign s_axi_awready=service_resetn && !aw_full && !s_axi_bvalid;
 assign s_axi_wready=service_resetn && !w_full && !s_axi_bvalid;
 assign s_axi_arready=service_resetn && (read_stage==0) && !s_axi_rvalid;
 integer b;
 always @(posedge service_clk) begin
  if(!service_resetn) begin
   aw_full<=0;w_full<=0;aw_addr<=0;w_data<=0;w_strb<=0;
   s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rresp<=0;s_axi_rdata<=0;
   read_stage<=0;read_addr<=0;selector<=0;read_diag<=0;
   read_base_data<=0;read_diag_data<=0;read_response<=0;
   diagnostic_control<=0;cpu_pending<=0;cpu_enable<=0;gate_manual<=0;
   buttons_meta<=0;buttons_sync<=0;buttons_previous<=0;
   cpu_overlay_enable<=0;cpu_word_index<=0;cpu_word_writes<=0;cpu_last_word<=0;
   cpu_pixel_index<=0;cpu_pixel_writes<=0;
  end else begin
   buttons_meta<=~buttons_n;buttons_sync<=buttons_meta;buttons_previous<=buttons_sync;
   if(s_axi_awvalid && s_axi_awready) begin aw_full<=1;aw_addr<=s_axi_awaddr;end
   if(s_axi_wvalid && s_axi_wready) begin w_full<=1;w_data<=s_axi_wdata;w_strb<=s_axi_wstrb;end
   if(s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
   if(commit) begin
    aw_full<=0;w_full<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    case(aw_addr)
     12'h010:for(b=0;b<4;b=b+1) if(w_strb[b])
       diagnostic_control[b*8+:8]<=w_data[b*8+:8];
     12'h024:if(w_strb[0] && w_data[0]) cpu_pending<=0;
     12'h028:if(w_strb[0]) cpu_enable<=w_data[0];
     12'h084:if(C_MANUAL_OVERRIDE) begin
      if(w_strb[0]) gate_manual<=w_data[0];
     end else s_axi_bresp<=2'b10;
     12'h200:if(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS) begin
      if(w_strb[0])cpu_overlay_enable<=w_data[0];
     end else s_axi_bresp<=2'b10;
     12'h204:if(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS && w_strb==15 && w_data<5760)
      cpu_word_index<=w_data[12:0];else s_axi_bresp<=2'b10;
     12'h208:if(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS && cpu_word_index<5760) begin
      if(|w_strb)begin
       cpu_word_index<=cpu_word_index==5759?13'd0:cpu_word_index+1'b1;
       cpu_word_writes<=cpu_word_writes+1'b1;cpu_last_word<=w_data;
      end
     end else s_axi_bresp<=2'b10;
     12'h224:if(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS && w_strb==15 && w_data<92160)
      cpu_pixel_index<=w_data[16:0];else s_axi_bresp<=2'b10;
     12'h228:if(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS)begin
      if(w_strb[0])begin
       cpu_pixel_index<=cpu_pixel_index==92159?17'd0:cpu_pixel_index+1'b1;
       cpu_pixel_writes<=cpu_pixel_writes+1'b1;
      end
     end else s_axi_bresp<=2'b10;
     default:s_axi_bresp<=2'b10; // SLVERR: reserved or read-only
    endcase
   end
   // New event wins over simultaneous CPU acknowledgment.
   if(button_change) cpu_pending<=1;
   if(s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
   if(s_axi_arvalid && s_axi_arready) begin
    read_stage<=1;read_addr<=s_axi_araddr;
    selector<=bank_read ? {1'b0,s_axi_araddr[5:2]} : diagnostic_control[4:0];
    read_diag<=bank_read || (s_axi_araddr==12'h018);
   end
   if(read_stage==1) begin
    read_stage<=2;read_response<=0;read_base_data<=0;
    read_diag_data<=diagnostic_data;
    if(read_addr[1:0]!=0) read_response<=2'b10;
    else if(read_diag) begin end
    else case(read_addr)
     12'h000:read_base_data<=32'h47424553; // GBES
     12'h004:read_base_data<=32'h00010005; // independent CPU alpha and ink
     12'h008:read_base_data<=7 | ((C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS)?216:0);
     12'h00c:read_base_data<=32'd200000000;
     12'h010:read_base_data<=diagnostic_control;
     12'h014:read_base_data<={29'b0,cpu_irq,cpu_pending,irq_request};
     12'h020:read_base_data<={20'b0,host_buttons};
     12'h024:read_base_data<={31'b0,cpu_pending};
     12'h028:read_base_data<={31'b0,cpu_enable};
     12'h080:read_base_data<=32'h47424952;
     12'h084:read_base_data<={31'b0,gate_manual};
     12'h088:read_base_data<={29'b0,gate_asserted,gate_sync[1],irq_request};
     12'h08c:read_base_data<=C_MANUAL_OVERRIDE;
     12'h090:read_base_data<=2;
     12'h200:read_base_data<={31'd0,cpu_overlay_enable};
     12'h204:read_base_data<={19'd0,cpu_word_index};
     12'h208:read_base_data<=cpu_last_word; // last write, NOT framebuffer readback
     12'h20c:read_base_data<={16'd240,16'd384};
     12'h210:read_base_data<=cpu_word_writes;
     12'h214:read_base_data<=(C_ENABLE_CPU_OVERLAY && C_ENABLE_OVERLAY_AXIS)?32'h434f5632:32'd0;
     12'h218:read_base_data<=2; // bits per pixel: {opaque,white}
     12'h21c:read_base_data<=5760; // packed word count
     12'h224:read_base_data<={15'd0,cpu_pixel_index};
     12'h22c:read_base_data<=cpu_pixel_writes;
     12'h230:read_base_data<=92160; // logical pixel count
     default:read_response<=2'b10;
    endcase
   end
   if(read_stage==2) begin
    read_stage<=0;s_axi_rvalid<=1;s_axi_rresp<=read_response;
    s_axi_rdata<=(read_response!=0) ? 32'b0 :
                 (read_diag ? read_diag_data : read_base_data);
   end
  end
 end
endmodule
