/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* License details: LICENSE.md at repository root. */
#ifndef GBAUDIO_H
#define GBAUDIO_H
#include "xil_types.h"
#include "xstatus.h"
#include "gbaudio_hw.h"

/** @file gbaudio.h
 * @defgroup gbaudio GBAudio bounded tone generator
 * @{ */
typedef struct {
    char *Name;
    UINTPTR BaseAddress;
} GBAudio_Config;

typedef struct {
    GBAudio_Config Config;
    u32 IsReady;
    u32 ClockHz;
} GBAudio;

/** Tone parameters: 20..12000 Hz, 0..100 percent PCM amplitude, waveform
 * GBAUDIO_SINE/SQUARE/TRIANGLE, channels GBAUDIO_BOTH/LEFT/RIGHT, and independent
 * session duration 100..30000 ms. DAC analog volume is managed by the ESP32.
 */
typedef struct {
    u32 FrequencyHz, LevelPercent, Waveform, Channels, LimitMs;
} GBAudio_Tone;

extern GBAudio_Config GBAudio_ConfigTable[];
/** Exact control-base lookup; zero selects the first discovered BSP instance. */
GBAudio_Config *GBAudio_LookupConfig(UINTPTR BaseAddress);
/** Validate ID and clocks without changing hardware state (including running tone). */
int GBAudio_CfgInitialize(GBAudio *Instance, const GBAudio_Config *Config,
                          UINTPTR EffectiveAddress);
/** Read-only identification; no acoustic/serializer proof. */
int GBAudio_SelfTest(const GBAudio *Instance);
/** Raw status flags, or zero for an uninitialized instance (not an error code). */
u32 GBAudio_Status(const GBAudio *Instance);
/** Set all tone parameters while stopped. Caller serializes competing writers. */
int GBAudio_Configure(const GBAudio *Instance, const GBAudio_Tone *Tone);
/** Start previously validated tone. Hardware stop_n and watchdog remain effective. */
int GBAudio_Start(const GBAudio *Instance);
/** Explicit stop; does not block waiting for asynchronous engine state. */
int GBAudio_Stop(const GBAudio *Instance);
/** Refresh 500ms lease; does not extend total duration. Call well before 500ms. */
int GBAudio_Heartbeat(const GBAudio *Instance);
/** Nominal sample rate from actual configured MCLK / 608, in Hz. */
double GBAudio_SampleRate(const GBAudio *Instance);
/** @} */
#endif
