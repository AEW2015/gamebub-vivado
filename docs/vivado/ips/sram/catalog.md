# gamebub_sram_mem component catalog

Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.

- VLNV: `gamebub.org:ip:gamebub_sram_mem:1.6`
- Component version: `1.6`
- Component metadata SHA-256: `ecdb822e7654a8ab3bbf026d75fd1ba1372c046a16c70ae4899f4daba73484c8`
- Source: [`component.xml`](../../../../fpga/ip_repo/gamebub_sram_mem_v1_6/component.xml)

## User parameters

Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve="user"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.

| Parameter | Default | Description |
| --- | --- | --- |
| `C_DEFAULT_TEST_WORDS` | `4096` | Initial destructive-test word count |
| `Component_Name` | `gamebub_sram_mem_0` | No description supplied in component metadata. |
| `USE_BOARD_FLOW` | `false` | No description supplied in component metadata. |
| `SRAM_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `C_MEMORY_BYTES` | `524288` | Fixed memory size (bytes) |
| `C_ADVANCED_SETTINGS` | `false` | Show advanced settings |

## Bus interfaces and clock/reset association

Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.

| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CTRL_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → CTRL_AXI_awaddr<br>AWPROT → CTRL_AXI_awprot<br>AWVALID → CTRL_AXI_awvalid<br>AWREADY → CTRL_AXI_awready<br>WDATA → CTRL_AXI_wdata<br>WSTRB → CTRL_AXI_wstrb<br>WVALID → CTRL_AXI_wvalid<br>WREADY → CTRL_AXI_wready<br>BRESP → CTRL_AXI_bresp<br>BVALID → CTRL_AXI_bvalid<br>BREADY → CTRL_AXI_bready<br>ARADDR → CTRL_AXI_araddr<br>ARPROT → CTRL_AXI_arprot<br>ARVALID → CTRL_AXI_arvalid<br>ARREADY → CTRL_AXI_arready<br>RDATA → CTRL_AXI_rdata<br>RRESP → CTRL_AXI_rresp<br>RVALID → CTRL_AXI_rvalid<br>RREADY → CTRL_AXI_rready | — | — | — |
| MEM_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → MEM_AXI_awaddr<br>AWPROT → MEM_AXI_awprot<br>AWVALID → MEM_AXI_awvalid<br>AWREADY → MEM_AXI_awready<br>WDATA → MEM_AXI_wdata<br>WSTRB → MEM_AXI_wstrb<br>WVALID → MEM_AXI_wvalid<br>WREADY → MEM_AXI_wready<br>BRESP → MEM_AXI_bresp<br>BVALID → MEM_AXI_bvalid<br>BREADY → MEM_AXI_bready<br>ARADDR → MEM_AXI_araddr<br>ARPROT → MEM_AXI_arprot<br>ARVALID → MEM_AXI_arvalid<br>ARREADY → MEM_AXI_arready<br>RDATA → MEM_AXI_rdata<br>RRESP → MEM_AXI_rresp<br>RVALID → MEM_AXI_rvalid<br>RREADY → MEM_AXI_rready | — | — | — |
| host_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → host_resetn | — | — | — |
| SRAM | gamebub.org:interface:sram:1.0 | gamebub.org:interface:sram_rtl:1.0 | master | A → sram_a<br>IO → sram_io<br>CE_N → sram_ce_n<br>OE_N → sram_oe_n<br>WE_N → sram_we_n<br>UB_N → sram_ub_n<br>LB_N → sram_lb_n | — | — | — |
| host_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → host_clk | — | host_resetn | MEM_AXI:CTRL_AXI |

## Top-level HDL ports

Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.

| Port | Direction | Vector bounds |
| --- | --- | --- |
| `host_clk` | `in` | `scalar` |
| `host_resetn` | `in` | `scalar` |
| `healthy` | `out` | `scalar` |
| `clock_fault` | `out` | `scalar` |
| `test_grant` | `out` | `scalar` |
| `switching` | `out` | `scalar` |
| `sram_a` | `out` | `[17:0]` |
| `sram_io` | `inout` | `[15:0]` |
| `sram_ce_n` | `out` | `scalar` |
| `sram_oe_n` | `out` | `scalar` |
| `sram_we_n` | `out` | `scalar` |
| `sram_ub_n` | `out` | `scalar` |
| `sram_lb_n` | `out` | `scalar` |
| `MEM_AXI_awaddr` | `in` | `[31:0]` |
| `MEM_AXI_awprot` | `in` | `[2:0]` |
| `MEM_AXI_awvalid` | `in` | `scalar` |
| `MEM_AXI_awready` | `out` | `scalar` |
| `MEM_AXI_wdata` | `in` | `[31:0]` |
| `MEM_AXI_wstrb` | `in` | `[3:0]` |
| `MEM_AXI_wvalid` | `in` | `scalar` |
| `MEM_AXI_wready` | `out` | `scalar` |
| `MEM_AXI_bresp` | `out` | `[1:0]` |
| `MEM_AXI_bvalid` | `out` | `scalar` |
| `MEM_AXI_bready` | `in` | `scalar` |
| `MEM_AXI_araddr` | `in` | `[31:0]` |
| `MEM_AXI_arprot` | `in` | `[2:0]` |
| `MEM_AXI_arvalid` | `in` | `scalar` |
| `MEM_AXI_arready` | `out` | `scalar` |
| `MEM_AXI_rdata` | `out` | `[31:0]` |
| `MEM_AXI_rresp` | `out` | `[1:0]` |
| `MEM_AXI_rvalid` | `out` | `scalar` |
| `MEM_AXI_rready` | `in` | `scalar` |
| `CTRL_AXI_awaddr` | `in` | `[31:0]` |
| `CTRL_AXI_awprot` | `in` | `[2:0]` |
| `CTRL_AXI_awvalid` | `in` | `scalar` |
| `CTRL_AXI_awready` | `out` | `scalar` |
| `CTRL_AXI_wdata` | `in` | `[31:0]` |
| `CTRL_AXI_wstrb` | `in` | `[3:0]` |
| `CTRL_AXI_wvalid` | `in` | `scalar` |
| `CTRL_AXI_wready` | `out` | `scalar` |
| `CTRL_AXI_bresp` | `out` | `[1:0]` |
| `CTRL_AXI_bvalid` | `out` | `scalar` |
| `CTRL_AXI_bready` | `in` | `scalar` |
| `CTRL_AXI_araddr` | `in` | `[31:0]` |
| `CTRL_AXI_arprot` | `in` | `[2:0]` |
| `CTRL_AXI_arvalid` | `in` | `scalar` |
| `CTRL_AXI_arready` | `out` | `scalar` |
| `CTRL_AXI_rdata` | `out` | `[31:0]` |
| `CTRL_AXI_rresp` | `out` | `[1:0]` |
| `CTRL_AXI_rvalid` | `out` | `scalar` |
| `CTRL_AXI_rready` | `in` | `scalar` |
