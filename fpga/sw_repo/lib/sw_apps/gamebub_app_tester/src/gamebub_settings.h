/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#ifndef GAMEBUB_TEMPLATE_SETTINGS_H
#define GAMEBUB_TEMPLATE_SETTINGS_H
/* App Tester only: pressing A on SRAM/SDRAM overwrites this 4-KiB range.
 * The native template links all code/data/stack to BRAM. Reserve the range
 * in BOTH memories and park other masters before RUNNING this application.
 * These defaults do not automatically stop DMA or other hardware clients.
 * Set GB_ALLOW_DESTRUCTIVE=0 to restore the guarded memory pages.
 */
#ifndef GB_ALLOW_DESTRUCTIVE
#define GB_ALLOW_DESTRUCTIVE 1
#endif
#ifndef GB_BRAM_EXECUTION_CONFIRMED
#define GB_BRAM_EXECUTION_CONFIRMED 1
#endif
#ifndef GB_SCRATCH_OFFSET
#define GB_SCRATCH_OFFSET 0x1000
#endif
#ifndef GB_SCRATCH_BYTES
#define GB_SCRATCH_BYTES 0x1000
#endif
#ifndef GB_ALLOW_RETIMING
#define GB_ALLOW_RETIMING 0
#endif
#endif
