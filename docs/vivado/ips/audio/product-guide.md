# Audio product guide

## Features and limits

The tone engine generates signed16-bit left/right samples, programmable20–12000 Hz frequency, linear digital level0–100%, sine/square/triangle, and both/left/right channels. Playback has a100–30000 ms total session limit plus an independent500 ms heartbeat lease. Boot/reset output is stopped. It is a diagnostic tone engine, not arbitrary PCM playback, mixer, resampler, file player or DMA endpoint.

The identity register is0x53504B01. There is **no separate ABI/capability register**: do not probe invented offsets. Current supported format and ranges follow the reviewed1.3 source.

## Clocks, reset and pins

`audio_clk` clocks both S_AXI and the tone/serializer engine. Use the reference pixel MMCM output, actual integer metadata29,361,979 Hz, and a synchronized active-low `audio_resetn`. A100MHz CPU requires an AXI clock converter or a correctly clocked interconnect output. Do not connect a100MHz AXI clock directly to this single-clock slave and hide a FREQ_HZ mismatch.

`stop_n` is an independent active-low stop input, synchronized internally through two flops. **An unconnected stop_n can be tied low by Vivado and prevent playback**. Connect it explicitly: pixel-domain `peripheral_aresetn` is appropriate for the reference design, or a genuine stop source normally high. It does not replace the AXI reset.

Use board automation for MCLK/WCLK/BCLK/DIN assignments. The external DAC must already be configured by ESP32 firmware; this IP does not have I2C codec setup or analog gain controls. Reprogramming FPGA via JTAG does not establish the ESP32 state or DAC volume automatically.

## DAC protocol and frequency assumptions

Format is DSP signed16-bit left then right, zero offset and zero padding. The DAC samples on falling BCLK. MCLK is audio clock; BCLK=MCLK/8; each stereo frame occupies608MCLK cycles. Therefore nominal Fs=29,361,979/608=48,292.7286 Hz using integer metadata (the physical wizard ratio is fractionally higher). The SAMPLE_RATE register returns fixed rounded48293, not measured rate.

The DDS uses a fixed step-per-Hz multiplier88936 derived for nominal29.361979MHz. The1.3 wrapper does not expose `CLOCK_HZ` as a GUI parameter: its child uses default29361979. Even changing that child parameter in a future revision would not recalculate the multiplier. Arbitrary audio clocks alter generated pitch/sample rate, despite a legal AXI connection. Keep the nominal reference clock until a separately tested parameterized DDS update exists. `GBAudio_SampleRate` divides the reported constant by608; it does not measure physical clock accuracy.

## AXI control and safety

S_AXI is32-bit AXI4-Lite,4KiB aperture, one pending response in each direction with independent AW/W capture. Use full-strobe32-bit commands and heartbeat. Configuration supports byte strobes but changes are accepted only when stopped and no start pulse is pending. Unsupported/misaligned accesses, invalid commands, or configuration writes while running return SLVERR. Invalid field values can be staged while stopped but a start is rejected unless all fields are valid. Driver range checks prevent ordinary invalid accesses but cannot observe AXI BRESP directly.

The engine starts only on explicit command1; command2 stops. A heartbeat key refreshes lease500 ms, never extends total session duration. Hardware reason fields report0 normal/software stop,2 lease expiry,3 external stop,4 session expiry. `stop_n` may override a start; configuration/start success means a legal MMIO sequence, not proof the engine ran or speaker was audible.

Always start at a low digital amplitude, for example5%, and a short250 ms limit. The DAC's saved analog volume is independent;5% digital amplitude is not a guaranteed acoustic safety level. No automatic listening test runs on initialization or driver self-test. For longer deliberate sessions, foreground code refreshes heartbeat well before500 ms and stops on app exit/error; no unbounded busy-wait is required. Hardware watchdogs still operate if CPU servicing stops.

No global reset or codec mute is performed by `CfgInitialize`. It only reads identity/clock; if an existing tone is running it stays in that state until explicitly stopped. Reset of the hardware stops tone; driver reinitialization is not a substitute for it.

## Debugging

1. Read identity and clock; check the slave is on the pixel clock and source AXI crossing exists.
2. Check `stop_n` is high after synchronized reset release.
3. Check STATUS running/reason, REMAINING and advancing frame count.
4. Verify explicit configure/start and heartbeat cadence; app switching must stop audio.
5. If digital activity is good but silence remains, inspect ESP32 DAC initialization, analog volume, output route and headphones/speaker state.

Resource and timing utilization are full-design properties. No new implementation or external-DAC timing qualification is claimed here. Refer to the final build's report and serializer simulation for performance and pin-level evidence.
