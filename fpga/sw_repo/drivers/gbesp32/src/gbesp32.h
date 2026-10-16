/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* License details: LICENSE.md at repository root. */
#ifndef GBESP32_H
#define GBESP32_H
#include "xil_types.h"
#include "xstatus.h"
#include "gbesp32_hw.h"

/** @file gbesp32.h
 * @defgroup gbesp32 GBEsp32 communications and independent CPU overlay
 * @{ */
/** SDT compatible + reg schema order. Table terminates with Name=NULL. */
typedef struct {
    char *Name;
    UINTPTR BaseAddress;
} GBEsp32_Config;

typedef struct {
    GBEsp32_Config Config;
    u32 IsReady;
    u32 Capabilities;
} GBEsp32;

extern GBEsp32_Config GBEsp32_ConfigTable[];
/** Return configuration for BaseAddress, or first instance when zero. */
GBEsp32_Config *GBEsp32_LookupConfig(UINTPTR BaseAddress);
/** Read-only identification; no reset, IRQ acknowledge or framebuffer writes. */
int GBEsp32_CfgInitialize(GBEsp32 *Instance, const GBEsp32_Config *Config,
                          UINTPTR EffectiveAddress);
/** Read-only ID/ABI validation. Does not prove physical QSPI or buttons. */
int GBEsp32_SelfTest(const GBEsp32 *Instance);
/** Current pressed host bitmap (12 bits), not an event queue. */
u32 GBEsp32_Buttons(const GBEsp32 *Instance);
/** CPU-latched pending flag; reading does not acknowledge the interrupt.
 * Returns zero for an uninitialized instance, as does Buttons().
 */
u32 GBEsp32_IrqPending(const GBEsp32 *Instance);
/** Enable/disable level interrupt without clearing its independent CPU latch. */
int GBEsp32_IrqEnable(const GBEsp32 *Instance, u32 Enable);
/** W1C CPU latch; new hardware button change wins over simultaneous clear. */
int GBEsp32_IrqAcknowledge(const GBEsp32 *Instance);
/** Non-mutating diagnostic bank read; Selector must be 0..15. */
int GBEsp32_Diagnostic(const GBEsp32 *Instance, u32 Selector, u32 *Value);
/** Enable COV2 layer only when its runtime capability/identity is present. */
int GBEsp32_OverlayEnable(const GBEsp32 *Instance, u32 Enable);
/** Set one 384x240 logical pixel; Colour is {opaque,white}, 0..3, LSB first.
 * Use TRANSPARENT=0, BLACK=2 or WHITE=3. Serialize index/data writers;
 * this CPU layer sits below the independently ESP32-owned menu layer.
 */
int GBEsp32_OverlayPixel(const GBEsp32 *Instance, u32 X, u32 Y, u32 Colour);
/** Write Count words, 16 two-bit pixels per word, without index wrap. */
int GBEsp32_OverlayWords(const GBEsp32 *Instance, u32 First, const u32 *Words, u32 Count);
/** Bounded 5760-word fill. Not frame atomic; caller serializes all writers. */
int GBEsp32_OverlayClear(const GBEsp32 *Instance, u32 Colour);
/** @} */
#endif
