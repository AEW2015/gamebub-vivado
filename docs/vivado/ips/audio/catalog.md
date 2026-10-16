# gamebub_dac_audio component catalog

Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.

- VLNV: `gamebub.org:ip:gamebub_dac_audio:1.3`
- Component version: `1.3`
- Component metadata SHA-256: `2699e376c18d2415cf33873205caf20afb3f5f6abfa2b06adfd41290ff1c673b`
- Source: [`component.xml`](../../../../fpga/ip_repo/gamebub_dac_audio_v1_3/component.xml)

## User parameters

Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve="user"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.

| Parameter | Default | Description |
| --- | --- | --- |
| `C_DEFAULT_FREQUENCY` | `440` | Initial tone frequency (Hz) |
| `C_DEFAULT_LEVEL` | `10` | Initial digital level (percent) |
| `C_DEFAULT_LIMIT_MS` | `5000` | Initial playback session limit (ms) |
| `Component_Name` | `gamebub_dac_audio_0` | No description supplied in component metadata. |
| `USE_BOARD_FLOW` | `false` | No description supplied in component metadata. |
| `AUDIO_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |

## Bus interfaces and clock/reset association

Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.

| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S_AXI | xilinx.com:interface:aximm:1.0 | xilinx.com:interface:aximm_rtl:1.0 | slave | AWADDR → S_AXI_awaddr<br>AWPROT → S_AXI_awprot<br>AWVALID → S_AXI_awvalid<br>AWREADY → S_AXI_awready<br>WDATA → S_AXI_wdata<br>WSTRB → S_AXI_wstrb<br>WVALID → S_AXI_wvalid<br>WREADY → S_AXI_wready<br>BRESP → S_AXI_bresp<br>BVALID → S_AXI_bvalid<br>BREADY → S_AXI_bready<br>ARADDR → S_AXI_araddr<br>ARPROT → S_AXI_arprot<br>ARVALID → S_AXI_arvalid<br>ARREADY → S_AXI_arready<br>RDATA → S_AXI_rdata<br>RRESP → S_AXI_rresp<br>RVALID → S_AXI_rvalid<br>RREADY → S_AXI_rready | — | — | — |
| audio_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → audio_resetn | — | — | — |
| audio_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → audio_clk | — | audio_resetn | S_AXI:AUDIO |
| AUDIO | gamebub.org:interface:dac_dsp:1.0 | gamebub.org:interface:dac_dsp_rtl:1.0 | master | MCLK → dac_mclk<br>WCLK → dac_wclk<br>BCLK → dac_bclk<br>DIN → dac_din | — | — | — |

## Top-level HDL ports

Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.

| Port | Direction | Vector bounds |
| --- | --- | --- |
| `audio_clk` | `in` | `scalar` |
| `audio_resetn` | `in` | `scalar` |
| `stop_n` | `in` | `scalar` |
| `dac_mclk` | `out` | `scalar` |
| `dac_bclk` | `out` | `scalar` |
| `dac_wclk` | `out` | `scalar` |
| `dac_din` | `out` | `scalar` |
| `S_AXI_awaddr` | `in` | `[31:0]` |
| `S_AXI_awprot` | `in` | `[2:0]` |
| `S_AXI_awvalid` | `in` | `scalar` |
| `S_AXI_awready` | `out` | `scalar` |
| `S_AXI_wdata` | `in` | `[31:0]` |
| `S_AXI_wstrb` | `in` | `[3:0]` |
| `S_AXI_wvalid` | `in` | `scalar` |
| `S_AXI_wready` | `out` | `scalar` |
| `S_AXI_bresp` | `out` | `[1:0]` |
| `S_AXI_bvalid` | `out` | `scalar` |
| `S_AXI_bready` | `in` | `scalar` |
| `S_AXI_araddr` | `in` | `[31:0]` |
| `S_AXI_arprot` | `in` | `[2:0]` |
| `S_AXI_arvalid` | `in` | `scalar` |
| `S_AXI_arready` | `out` | `scalar` |
| `S_AXI_rdata` | `out` | `[31:0]` |
| `S_AXI_rresp` | `out` | `[1:0]` |
| `S_AXI_rvalid` | `out` | `scalar` |
| `S_AXI_rready` | `in` | `scalar` |
