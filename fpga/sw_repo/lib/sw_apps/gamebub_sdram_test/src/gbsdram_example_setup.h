#ifndef GBSDRAM_EXAMPLE_SETUP_H
#define GBSDRAM_EXAMPLE_SETUP_H
#include "gbsdram.h"
#include "xil_printf.h"
#if defined(GB_EXAMPLE_CTRL_BASE) && defined(GB_EXAMPLE_MEMORY_BASE) && defined(GB_SCRATCH_OFFSET) && defined(GB_SCRATCH_BYTES) && defined(GB_ALLOW_DESTRUCTIVE) && GB_ALLOW_DESTRUCTIVE == 1 && defined(GB_BRAM_EXECUTION_CONFIRMED) && GB_BRAM_EXECUTION_CONFIRMED == 1
#define GBSDRAM_EXAMPLE_ARMED 1
#include "xil_cache.h"
static int setup(GBSdram *s,GBSdram_Reservation *r) {
 GBSdram_Config c={"xsa_sdram",GB_EXAMPLE_CTRL_BASE};int rc=GBSdram_CfgInitialize(s,&c,c.BaseAddress);
 if(rc!=XST_SUCCESS)return rc;
 rc=GBSdram_BindMemory(s,GB_EXAMPLE_MEMORY_BASE,GBSDRAM_BYTES);if(rc!=XST_SUCCESS)return rc;
 Xil_DCacheFlush();Xil_DCacheDisable();
 r->Offset=GB_SCRATCH_OFFSET;r->Size=GB_SCRATCH_BYTES;r->AllClientsParked=1;r->CacheMaintained=1;
 return GBSdram_SetOwner(s,GBSDRAM_OWNER_CPU,1000000);
}
#endif
#endif
