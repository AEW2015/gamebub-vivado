/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* License details: LICENSE.md at repository root. */
/** @file gbsram.h
 * @brief GameBub SRAM control driver (gamebub_sram_mem 1.6).
 * RAM is normal memory, not a register-transfer abstraction. Run all ownership
 * changes from BRAM with all other SRAM clients parked and caches maintained.
 * PollBudget bounds register polls, not elapsed time or a stalled AXI access.
 */
#ifndef GBSRAM_H
#define GBSRAM_H
#include "xil_types.h"
#include "xstatus.h"
#include "gbsram_hw.h"
#ifdef __cplusplus
extern "C" {
#endif
/** SDT table layout: instance name, then CTRL_AXI base (never MEM_AXI base). */
typedef struct {
    char *Name;
    UINTPTR BaseAddress;
} GBSram_Config;

typedef struct {
    GBSram_Config Config;
    UINTPTR MemoryBaseAddress;
    u32 MemorySize;
    u32 IsReady;
} GBSram;

/** Explicit reservation, in bytes, relative to MEM_AXI. Destructive consent. */
typedef struct {
    u32 Offset;
    u32 Size;
    int AllClientsParked;
    int CacheMaintained;
} GBSram_Reservation;

/** Hardware-test result is a snapshot, not a board timing qualification. */
typedef struct {
    u32 Passes;
    u32 Failures;
    u32 Completed;
    u32 Reads;
    u32 Writes;
} GBSram_TestResult;

extern GBSram_Config GBSram_ConfigTable[];
/** Find an exact control-base match; NULL if absent. Zero is not a wildcard. */
GBSram_Config *GBSram_LookupConfig(UINTPTR BaseAddress);
/** Read-only ID/capability validation; does not run a memory test or reset RAM. */
int GBSram_CfgInitialize(GBSram *Self, const GBSram_Config *Config, UINTPTR EffectiveAddr);
/** Check control-register identity, not physical memory cells or timing. */
int GBSram_SelfTest(GBSram *Self);
/** Bind the full aligned 512-KiB MEM_AXI aperture; no allocation/cache changes. */
int GBSram_BindMemory(GBSram *Self, UINTPTR MemoryBase, u32 Size);
/** Poll for idle and CPU ownership; failure may mean fault or budget exhausted. */
int GBSram_WaitReady(GBSram *Self, u32 PollBudget);
/** Destructive 32-bit CPU test, including independent byte-lane writes.
 * Cache must be disabled for this RAM span (flush dirty lines first).
 * @param Self Initialized driver with the complete MEM_AXI aperture bound.
 * @param Range Reserved byte span and caller-managed safety assertions.
 * @param FailOffset Receives a byte offset into RAM on comparison failure only.
 * @return XST_SUCCESS, XST_INVALID_PARAM, or XST_FAILURE; contents are not restored.
 */
int GBSram_ScratchTest(GBSram *Self, const GBSram_Reservation *Range, u32 *FailOffset);
/** Run one completed hardware pattern pass, then STOP and wait for CPU grant.
 * Pattern 0..8; uses current active timings (no clock/timing modification).
 * Range may start/end on halfwords; offset and size must be even.
 * Results are cumulative; a prior recorded failure still makes this call fail.
 * On timeout/fault, inspect ownership before permitting external RAM clients.
 */
int GBSram_RunTest(GBSram *Self, const GBSram_Reservation *Range, u32 Pattern, u32 PollBudget,
                   GBSram_TestResult *Result);
#ifdef __cplusplus
}
#endif
#endif
