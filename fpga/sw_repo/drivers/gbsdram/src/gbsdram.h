/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* License details: LICENSE.md at repository root. */
/** @file gbsdram.h
 * @brief GameBub SERDES4 SDR SDRAM 1.6 control, not an AXI burst engine.
 * All retiming/test/ownership code, stack, traps and interrupts must be BRAM
 * resident; clients must be parked and dirty cache lines flushed first.
 * PollBudget counts polls; it is not a clock-based deadline or bus timeout.
 */
#ifndef GBSDRAM_H
#define GBSDRAM_H
#include "xil_types.h"
#include "xstatus.h"
#include "gbsdram_hw.h"
#ifdef __cplusplus
extern "C" {
#endif
/** SDT table layout: instance name, then the unified 8-KiB CTRL_AXI base. */
typedef struct {
    char *Name;
    UINTPTR BaseAddress;
} GBSdram_Config;

typedef struct {
    GBSdram_Config Config;
    UINTPTR MemoryBaseAddress;
    u32 MemorySize;
    u32 IsReady;
} GBSdram;

/** Byte range relative to MEM_AXI, plus caller-managed safety assertions.
 * A nonzero flag does not actually park hardware masters or maintain caches.
 */
typedef struct {
    u32 Offset;
    u32 Size;
    int AllClientsParked;
    int CacheMaintained;
} GBSdram_Reservation;

/** Coherent hardware snapshot; counts describe comparisons, not timing margin. */
typedef struct {
    u32 Status;
    u32 Compared;
    u32 ExpectedCompares;
    u32 Errors;
    u32 RunId;
} GBSdram_TestResult;

/** Clock ABI uses logical 50-MHz D; physical MMCM DIVCLK is 2*D. */
typedef struct {
    u32 M8;
    u32 D;
    u32 O;
    u32 SerialPhaseMilliDegrees;
    u32 QuarterPhaseMilliDegrees;
    u32 RequestedHz;
    u32 ActualHz;
} GBSdram_ClockProfile;

typedef struct {
    u32 Status;
    u32 Epoch;
    u32 NominalHz;
    u32 CommandKHz;
    u32 ReadKHz;
} GBSdram_ClockStatus;

/** Application verifies BRAM execution, cache flush and all-master parking.
 * Driver cannot infer those system-wide facts from a peripheral register.
 */
typedef int (*GBSdram_SafetyCheck)(void *Ref);
extern GBSdram_Config GBSdram_ConfigTable[];
/** Find an exact CTRL_AXI base match; NULL if absent. Zero is not a wildcard. */
GBSdram_Config *GBSdram_LookupConfig(UINTPTR BaseAddress);
/** Read-only control/clock identity checks; no ownership or timing changes. */
int GBSdram_CfgInitialize(GBSdram *Self, const GBSdram_Config *Config, UINTPTR EffectiveAddr);
/** Check register identity/ABI only; does not read or write physical RAM. */
int GBSdram_SelfTest(GBSdram *Self);
/** Bind the complete aligned 32-MiB MEM_AXI range without changing the linker. */
int GBSdram_BindMemory(GBSdram *Self, UINTPTR MemoryBase, u32 Size);
/** Ownership 0=PARK, 1=CPU, 2=TEST. Requires all external clients parked. */
int GBSdram_SetOwner(GBSdram *Self, u32 Owner, u32 PollBudget);
/** Request a coherent ownership snapshot through the command mailbox. */
int GBSdram_GetOwner(GBSdram *Self, u32 *Owner, u32 PollBudget);
/** Destructive four-pattern and byte-lane test through uncached CPU accesses.
 * Requires CPU ownership and a four-byte-aligned reserved range.
 * FailOffset receives a RAM-relative byte offset only on comparison mismatch.
 */
int GBSdram_ScratchTest(GBSdram *Self, const GBSdram_Reservation *Range, u32 *FailOffset);
/** Hardware nine-pattern engine. Range must be 16-byte aligned.
 * Remains in TEST ownership after return, including timeout; caller must
 * abort/drain and explicitly reacquire CPU before memory use.
 */
int GBSdram_RunTest(GBSdram *Self, const GBSdram_Reservation *Range, u32 PatternMask,
                    u32 PollBudget, GBSdram_TestResult *Result);
/** Request bounded engine abort; does not grant RAM back to the CPU. */
int GBSdram_Abort(GBSdram *Self, u32 PollBudget);
/** Pure exhaustive nearest-achievable profile search, 166..250 MHz.
 * Phase is serial degrees*1000; corresponding CLKDIV phase is one quarter.
 * ActualHz records the rounded achievable rate, not a hardware measurement.
 */
int GBSdram_CalculateClock(u32 RequestedHz, u32 SerialPhaseMilliDegrees,
                           GBSdram_ClockProfile *Profile);
/** Opt-in clock apply. Requires PARK, reconfig_safe, BRAM safety callback.
 * Leaves PARK ownership. Memory data is invalidated by reinitialization.
 * On failure do not resume RAM clients; recover from BRAM/reconfigure FPGA.
 */
int GBSdram_ApplyClock(GBSdram *Self, const GBSdram_ClockProfile *Profile,
                       GBSdram_SafetyCheck Safety, void *Ref, u32 PollBudget);
/** Read current clock telemetry without altering hardware. */
int GBSdram_GetClockStatus(GBSdram *Self, GBSdram_ClockStatus *Status);
/** Opt-in per-DQ taps0..31. Requires PARK and BRAM/client safety callback;
 * preserves capture/tag configuration, verifies all actual tap readbacks.
 */
int GBSdram_LoadTaps(GBSdram *Self, const u8 Taps[16], GBSdram_SafetyCheck Safety, void *Ref,
                     u32 PollBudget);
#ifdef __cplusplus
}
#endif
#endif
