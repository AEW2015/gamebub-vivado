# gamebub_esp32_v102 component catalog

Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.

- VLNV: `gamebub.org:ip:gamebub_esp32_v102:1.14`
- Component version: `1.14`
- Component metadata SHA-256: `bc866f9bbe9c1bd08034680bf974dfd30dfbe9922ea3e79f04e8f1337178f71d`
- Source: [`component.xml`](../../../../fpga/ip_repo/gamebub_esp32_v102_v1_14/component.xml)

## User parameters

Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve="user"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.

| Parameter | Default | Description |
| --- | --- | --- |
| `C_MANUAL_OVERRIDE` | `0` | Enable diagnostic manual ESP32 IRQ override |
| `Component_Name` | `gamebub_esp32_v102_0` | No description supplied in component metadata. |
| `QSPI_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `BUTTONS_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `IRQ_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `USE_BOARD_FLOW` | `false` | No description supplied in component metadata. |
| `C_ENABLE_OVERLAY_AXIS` | `false` | Enable AXI4-Stream overlay output |
| `C_OVERLAY_MONOCHROME` | `true` | Black/white plus transparency (6 BRAM36) |
| `C_OVERLAY_CLK_HZ` | `29361979` | Overlay stream clock frequency (Hz) |
| `C_ENABLE_CPU_OVERLAY` | `false` | Enable processor per-pixel opacity and black/white overlay |

## Bus interfaces and clock/reset association

Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.

| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |
| --- | --- | --- | --- | --- | --- | --- | --- |
| QSPI | gamebub.org:interface:esp32_qspi:1.0 | gamebub.org:interface:esp32_qspi_rtl:1.0 | slave | SCK → qspi_sck<br>CS_N → qspi_cs_n<br>DQ → qspi_dq | — | — | — |
| BUTTONS | xilinx.com:interface:gpio:1.0 | xilinx.com:interface:gpio_rtl:1.0 | master | TRI_I → buttons_n | — | — | — |
| IRQ_GATE | gamebub.org:interface:esp32_irq:1.0 | gamebub.org:interface:esp32_irq_rtl:1.0 | master | GATE → irq_gate | — | — | — |
| S_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → s_axi_awaddr<br>AWPROT → s_axi_awprot<br>AWVALID → s_axi_awvalid<br>AWREADY → s_axi_awready<br>WDATA → s_axi_wdata<br>WSTRB → s_axi_wstrb<br>WVALID → s_axi_wvalid<br>WREADY → s_axi_wready<br>BRESP → s_axi_bresp<br>BVALID → s_axi_bvalid<br>BREADY → s_axi_bready<br>ARADDR → s_axi_araddr<br>ARPROT → s_axi_arprot<br>ARVALID → s_axi_arvalid<br>ARREADY → s_axi_arready<br>RDATA → s_axi_rdata<br>RRESP → s_axi_rresp<br>RVALID → s_axi_rvalid<br>RREADY → s_axi_rready | — | — | — |
| service_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → service_clk | — | service_resetn | S_AXI:QSPI:BUTTONS:IRQ_GATE |
| service_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → service_resetn | — | — | — |
| cpu_irq | xilinx.com:signal:interrupt:1.0 | xilinx.com:signal:interrupt_rtl:1.0 | master | INTERRUPT → cpu_irq | — | — | — |
| overlay_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → overlay_resetn | — | — | — |
| overlay_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → overlay_clk | — | overlay_resetn | M_AXIS_OVERLAY |
| M_AXIS_OVERLAY | xilinx.com:interface:axis:1.0 | xilinx.com:interface:axis_rtl:1.0 | master | TDATA → M_AXIS_OVERLAY_tdata<br>TVALID → M_AXIS_OVERLAY_tvalid<br>TREADY → M_AXIS_OVERLAY_tready<br>TUSER → M_AXIS_OVERLAY_tuser<br>TLAST → M_AXIS_OVERLAY_tlast | — | — | — |

## Top-level HDL ports

Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.

| Port | Direction | Vector bounds |
| --- | --- | --- |
| `service_clk` | `in` | `scalar` |
| `service_resetn` | `in` | `scalar` |
| `qspi_sck` | `in` | `scalar` |
| `qspi_cs_n` | `in` | `scalar` |
| `qspi_dq` | `inout` | `[3:0]` |
| `buttons_n` | `in` | `[11:0]` |
| `irq_gate` | `out` | `scalar` |
| `cpu_irq` | `out` | `scalar` |
| `s_axi_awaddr` | `in` | `[11:0]` |
| `s_axi_awprot` | `in` | `[2:0]` |
| `s_axi_awvalid` | `in` | `scalar` |
| `s_axi_awready` | `out` | `scalar` |
| `s_axi_wdata` | `in` | `[31:0]` |
| `s_axi_wstrb` | `in` | `[3:0]` |
| `s_axi_wvalid` | `in` | `scalar` |
| `s_axi_wready` | `out` | `scalar` |
| `s_axi_bresp` | `out` | `[1:0]` |
| `s_axi_bvalid` | `out` | `scalar` |
| `s_axi_bready` | `in` | `scalar` |
| `s_axi_araddr` | `in` | `[11:0]` |
| `s_axi_arprot` | `in` | `[2:0]` |
| `s_axi_arvalid` | `in` | `scalar` |
| `s_axi_arready` | `out` | `scalar` |
| `s_axi_rdata` | `out` | `[31:0]` |
| `s_axi_rresp` | `out` | `[1:0]` |
| `s_axi_rvalid` | `out` | `scalar` |
| `s_axi_rready` | `in` | `scalar` |
| `overlay_clk` | `in` | `scalar` |
| `overlay_resetn` | `in` | `scalar` |
| `M_AXIS_OVERLAY_tdata` | `out` | `[31:0]` |
| `M_AXIS_OVERLAY_tvalid` | `out` | `scalar` |
| `M_AXIS_OVERLAY_tuser` | `out` | `scalar` |
| `M_AXIS_OVERLAY_tlast` | `out` | `scalar` |
| `M_AXIS_OVERLAY_tready` | `in` | `scalar` |
| `ov_wr` | `out` | `scalar` |
| `ov_addr` | `out` | `[17:0]` |
| `ov_data` | `out` | `[15:0]` |
