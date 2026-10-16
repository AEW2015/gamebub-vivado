# GBAudio software and examples

[Driver API](../../../../fpga/sw_repo/drivers/gbaudio/src/gbaudio.h) and [callable examples](../../../../fpga/sw_repo/drivers/gbaudio/examples) are independent of instance names and assigned base addresses.

`GBAudio_Config` uses SDT compatible/reg order `{Name,BaseAddress}`. `LookupConfig(0)` selects the first generated instance; an explicit address selects another. Checked-in `_g.c` is a safe empty fallback and must be replaced by generated configuration or bypassed with an application-supplied config. Neither `CfgInitialize` nor `SelfTest` writes registers or starts audio.

Initialization rejects a reported clock other than29,361,979Hz because the engine's fixed DDS scaling cannot provide the advertised frequency API at arbitrary clocks. This is a metadata compatibility check, **not a frequency measurement**: the1.3 wrapper reports a fixed constant, so the actual connected Clocking Wizard output must still be checked in Vivado.

```c
GBAudio audio;
GBAudio_Config *cfg = GBAudio_LookupConfig(platform_audio_base);
if (!cfg || GBAudio_CfgInitialize(&audio, cfg, cfg->BaseAddress))
    return XST_FAILURE;
/* Only on an explicit user request, after stop_n and DAC setup are ready: */
GBAudio_Tone tone = {440, 5, GBAUDIO_SINE, GBAUDIO_BOTH, 250};
if (GBAudio_Status(&audio) & GBAUDIO_RUNNING)
    return XST_FAILURE;
if (GBAudio_Configure(&audio, &tone))
    return XST_FAILURE;
return GBAudio_Start(&audio);
```

The tone helper `GBAudio_ToneExample` explicitly stops an earlier session, checks idle, configures440Hz/5%/sine/both/250ms, then starts. If a just-issued stop has not propagated, it returns failure: service the main loop and retry after checking status rather than spinning forever. It does not print or busy-wait. Hardware duration is shorter than the500ms watchdog, so the short demonstration needs no heartbeat.

`GBAudio_SafetyExample` reads status by default; optional stop is explicit. It is not a complete watchdog-expiry test. A longer app owns a monotonic time source, calls heartbeat comfortably before500ms, validates total duration and stops on exit/error. This BD does not contain a dedicated AXI timer; use a verified BSP counter or supplied deadline callback rather than assuming `sleep` or CPU clock estimates are accurate. The driver performs no unbounded waits.

Applications serialize all configuration/start/stop calls, including competing ISR/main-loop writers. Configuration/start is a multi-register sequence; no atomic ownership lock exists in hardware. `Start` revalidates live fields but cannot close a race with another AXI writer. Low-level MMIO failures can trap or stall before C error reporting; an exception handler/system timeout is a separate platform concern.

The driver returns `XST_INVALID_PARAM` for bad pointers/ranges, `XST_FAILURE` for wrong identity, unsupported state or already-running configuration/start. MMIO command acceptance is not physical-output confirmation. Read status/reason afterward to diagnose stop inputs/watchdogs.

The example sources include standalone mains; define `TESTAPP_GEN` for callable-library use with your own main. `audio_tone` defaults to a read-only self-test: deliberately define `GBAUDIO_ENABLE_AUDIBLE_EXAMPLE` to enable its bounded tone. YAML uses the observed native SDT compatible `xlnx,gamebub-dac-audio-1.3`. CMake handles Vitis-generated `GbaudioExample.cmake` metadata or a callable library. Native discovery and Import Examples still need actual clean-workspace evidence; a manual host compilation is not successful Vitis import.
