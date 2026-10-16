#ifndef GBSRAM_EXAMPLE_SETUP_H
#define GBSRAM_EXAMPLE_SETUP_H
#include "gbsram.h"
#include "xil_printf.h"
#if defined(GB_EXAMPLE_CTRL_BASE) && defined(GB_EXAMPLE_MEMORY_BASE) && defined(GB_SCRATCH_OFFSET) && defined(GB_SCRATCH_BYTES) && defined(GB_ALLOW_DESTRUCTIVE) && GB_ALLOW_DESTRUCTIVE == 1 && defined(GB_BRAM_EXECUTION_CONFIRMED) && GB_BRAM_EXECUTION_CONFIRMED == 1
#define GBSRAM_EXAMPLE_ARMED 1
#include "xil_cache.h"
static int setup(GBSram *s,GBSram_Reservation *r) {
 GBSram_Config c={"xsa_sram",GB_EXAMPLE_CTRL_BASE};int rc=GBSram_CfgInitialize(s,&c,c.BaseAddress);
 if(rc!=XST_SUCCESS)return rc;
 rc=GBSram_BindMemory(s,GB_EXAMPLE_MEMORY_BASE,GBSRAM_BYTES);if(rc!=XST_SUCCESS)return rc;
 /* Preconditions: all other masters parked; all data cache must be flushed. */
 Xil_DCacheFlush();Xil_DCacheDisable();
 r->Offset=GB_SCRATCH_OFFSET;r->Size=GB_SCRATCH_BYTES;r->AllClientsParked=1;r->CacheMaintained=1;
 return GBSram_WaitReady(s,1000000);
}
#endif
#endif
