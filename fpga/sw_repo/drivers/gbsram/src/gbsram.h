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
typedef struct { char *Name; UINTPTR BaseAddress; } GBSram_Config;
typedef struct {
 GBSram_Config Config; UINTPTR MemoryBaseAddress; u32 MemorySize; u32 IsReady;
} GBSram;
/** Explicit reservation, in bytes, relative to MEM_AXI. Destructive consent. */
typedef struct { u32 Offset; u32 Size; int AllClientsParked; int CacheMaintained; } GBSram_Reservation;
/** Hardware-test result is a snapshot, not a board timing qualification. */
typedef struct { u32 Passes; u32 Failures; u32 Completed; u32 Reads; u32 Writes; } GBSram_TestResult;
extern GBSram_Config GBSram_ConfigTable[];
GBSram_Config *GBSram_LookupConfig(UINTPTR BaseAddress);
int GBSram_CfgInitialize(GBSram *Self, const GBSram_Config *Config, UINTPTR EffectiveAddr);
int GBSram_SelfTest(GBSram *Self);
int GBSram_BindMemory(GBSram *Self, UINTPTR MemoryBase, u32 Size);
int GBSram_WaitReady(GBSram *Self, u32 PollBudget);
/** Destructive 32-bit CPU test, including independent byte-lane writes.
 * Cache must be disabled for this RAM span (flush dirty lines first).
 */
int GBSram_ScratchTest(GBSram *Self, const GBSram_Reservation *Range, u32 *FailOffset);
/** Run one completed hardware pattern pass, then STOP and wait for CPU grant.
 * Pattern 0..8; uses current active timings (no clock/timing modification).
 * Range may start/end on halfwords; offset and size must be even.
 */
int GBSram_RunTest(GBSram *Self, const GBSram_Reservation *Range,
                  u32 Pattern, u32 PollBudget, GBSram_TestResult *Result);
#ifdef __cplusplus
}
#endif
#endif
