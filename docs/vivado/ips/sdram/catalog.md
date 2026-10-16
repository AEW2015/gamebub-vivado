# gamebub_sdram_mem component catalog

Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.

- VLNV: `gamebub.org:ip:gamebub_sdram_mem:1.6`
- Component version: `1.6`
- Component metadata SHA-256: `869cd5b971e3d654c1e3c96272f03b022401c8238f3cca0bce8be2bfaba9c341`
- Source: [`component.xml`](../../../../fpga/ip_repo/gamebub_sdram_mem_v1_6/component.xml)

## User parameters

Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve="user"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.

| Parameter | Default | Description |
| --- | --- | --- |
| `C_BASE_ADDR` | `1610612736` | Absolute processor SDRAM data base (64 MiB aligned) |
| `C_POWER_BEATS` | `15625` | Power-up command-clock beats (minimum safe at 250 MHz) |
| `C_TIMEOUT_CYCLES` | `131072` | Host mailbox timeout cycles |
| `C_METER_WINDOW` | `100000` | Frequency meter window (50000, 100000 or 200000) |
| `Component_Name` | `gamebub_sdram_mem_0` | No description supplied in component metadata. |
| `USE_BOARD_FLOW` | `false` | No description supplied in component metadata. |
| `SDRAM_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `C_MEMORY_BYTES` | `33554432` | Fixed memory size (bytes) |
| `C_ADVANCED_SETTINGS` | `false` | Show advanced settings |

## Bus interfaces and clock/reset association

Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.

| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CTRL_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → CTRL_AXI_awaddr<br>AWPROT → CTRL_AXI_awprot<br>AWVALID → CTRL_AXI_awvalid<br>AWREADY → CTRL_AXI_awready<br>WDATA → CTRL_AXI_wdata<br>WSTRB → CTRL_AXI_wstrb<br>WVALID → CTRL_AXI_wvalid<br>WREADY → CTRL_AXI_wready<br>BRESP → CTRL_AXI_bresp<br>BVALID → CTRL_AXI_bvalid<br>BREADY → CTRL_AXI_bready<br>ARADDR → CTRL_AXI_araddr<br>ARPROT → CTRL_AXI_arprot<br>ARVALID → CTRL_AXI_arvalid<br>ARREADY → CTRL_AXI_arready<br>RDATA → CTRL_AXI_rdata<br>RRESP → CTRL_AXI_rresp<br>RVALID → CTRL_AXI_rvalid<br>RREADY → CTRL_AXI_rready | — | — | — |
| MEM_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → MEM_AXI_awaddr<br>AWPROT → MEM_AXI_awprot<br>AWVALID → MEM_AXI_awvalid<br>AWREADY → MEM_AXI_awready<br>WDATA → MEM_AXI_wdata<br>WSTRB → MEM_AXI_wstrb<br>WVALID → MEM_AXI_wvalid<br>WREADY → MEM_AXI_wready<br>BRESP → MEM_AXI_bresp<br>BVALID → MEM_AXI_bvalid<br>BREADY → MEM_AXI_bready<br>ARADDR → MEM_AXI_araddr<br>ARPROT → MEM_AXI_arprot<br>ARVALID → MEM_AXI_arvalid<br>ARREADY → MEM_AXI_arready<br>RDATA → MEM_AXI_rdata<br>RRESP → MEM_AXI_rresp<br>RVALID → MEM_AXI_rvalid<br>RREADY → MEM_AXI_rready | — | — | — |
| host_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → host_resetn | — | — | — |
| ref_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → ref_resetn | — | — | — |
| SDRAM | gamebub.org:interface:sdram:1.0 | gamebub.org:interface:sdram_rtl:1.0 | master | A → sdram_a<br>BS → sdram_bs<br>DQ → sdram_dq<br>CLK → sdram_clk<br>WE_N → sdram_we_n<br>LDQM → sdram_ldqm<br>UDQM → sdram_udqm<br>CAS_N → sdram_cas_n<br>RAS_N → sdram_ras_n<br>CKE → sdram_cke<br>CS_N → sdram_cs_n | — | — | — |
| host_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → host_clk | — | host_resetn | MEM_AXI:CTRL_AXI |
| refclk200 | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → refclk200 | — | ref_resetn | — |

## Top-level HDL ports

Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.

| Port | Direction | Vector bounds |
| --- | --- | --- |
| `host_clk` | `in` | `scalar` |
| `host_resetn` | `in` | `scalar` |
| `refclk200` | `in` | `scalar` |
| `ref_resetn` | `in` | `scalar` |
| `reconfig_hold` | `in` | `scalar` |
| `memory_safe` | `out` | `scalar` |
| `reconfig_safe` | `out` | `scalar` |
| `link_fault` | `out` | `scalar` |
| `clock_ready` | `out` | `scalar` |
| `sdram_a` | `out` | `[12:0]` |
| `sdram_bs` | `out` | `[1:0]` |
| `sdram_cke` | `out` | `[1:0]` |
| `sdram_cs_n` | `out` | `[1:0]` |
| `sdram_clk` | `out` | `scalar` |
| `sdram_we_n` | `out` | `scalar` |
| `sdram_ldqm` | `out` | `scalar` |
| `sdram_udqm` | `out` | `scalar` |
| `sdram_cas_n` | `out` | `scalar` |
| `sdram_ras_n` | `out` | `scalar` |
| `sdram_dq` | `inout` | `[15:0]` |
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
