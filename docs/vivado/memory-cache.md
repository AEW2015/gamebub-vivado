# External memory ownership and caches

The independent SRAM and SDRAM cores expose a memory aperture and a separate control aperture. Only `MEM_AXI/Mem` is RAM. Never register CTRL_AXI or the MMCM register bank as linker memory.

| Memory | Physical capacity | Reference window |
| --- | --- | --- |
| SRAM | 524,288 bytes, 262,144 sixteen-bit words | `0x76000000..0x7607FFFF` |
| SDR SDRAM | 33,554,432 bytes, 16,777,216 sixteen-bit words | `0x78000000..0x79FFFFFF` |
| Local BRAM | 16,384 bytes in this diagram | `0x00000000..0x00003FFF` |

The reference enables 4 KiB instruction/data caches with cacheable windows `0x70000000..0x7FFFFFFF`, covering both RAMs while excluding peripherals around `0x40000000` and `0x44A00000`. The holes inside that window are still unmapped. Configure both cache windows explicitly: native automation previously chose only SRAM.

Both current memory slave interfaces are AXI4-Lite. SmartConnect decomposes upstream cache-line transactions; the memory cores do not accept native multi-beat AXI4 bursts. Cached execution support is not a bandwidth guarantee. No cache coherence, exclusive access, atomics or multi-master coherent-memory service is claimed.

## Safe initialization

1. Boot in BRAM with stack, traps and recovery functions in BRAM.
2. Initialize the control driver and check ID/ABI, controller health and readiness with a bounded poll budget.
3. Acquire normal memory ownership; inspect the grant before accessing RAM.
4. Bind the exact XSA-derived memory window. Do not infer its public base from a private controller constant.
5. Use a reserved scratch region first. Flush/invalidate as required, read back independent patterns and check error status.
6. Only then enable application use or copy a small function into qualified memory, performing both data and instruction-cache maintenance.

## Tester takeover and retiming

Stop all users, move execution/stack to BRAM, write back dirty cache lines, drain outstanding accesses, and request tester/parked ownership. Poll grant/idle with a deadline before changing timing. After the test or an external write, invalidate stale cache lines before resuming normal ownership. Never run a destructive full-memory test over active application sections.

Mark scratch/test examples destructive even if they normally restore data. CPU crashes, resets and failed reads can interrupt restoration. The full-span examples must require an explicit destructive opt-in and print the range before starting. Counter activity or cache hits alone are not evidence that SDRAM pins were exercised; include uncached/flush-controlled comparisons and a deliberately injected expected-error control.

Changing frequency, phase or taps may make the memory unusable. Display actual attainable frequency, not only the requested setting. Dynamic clock operations require a known recovery setting and a parked controller. Five selected dynamic timing vectors are the default smoke coverage; they are not an exhaustive eye diagram or PVT characterization.

## Vitis linker discovery

Custom controllers are exported as RAM in XSA, but the default 2025.2 SDT/linker flow does not automatically recognize these cores as supported memory controllers. Use the checked XSA-to-linker helper delivered with the software repository and verify its output in the application linker view. This is explicitly a helper-based registration path, not native discovery.

Keep startup sections in BRAM until memory has been acquired. An ELF whose initial data is loaded into external memory requires initialization/ownership before the debugger writes those segments; merely selecting RAM in the linker is insufficient. The 16 KiB BRAM reference cannot fit every older 32 KiB tester program unchanged. Check ELF load segments, map file and stack reservation per application.

The current SDRAM wrapper remaps public low address bits into a private decoder base. Keep alignment requirements and actual address translation tests with the controller guide. A difference between an internal base parameter and Address Editor is not by itself proof of failure.
