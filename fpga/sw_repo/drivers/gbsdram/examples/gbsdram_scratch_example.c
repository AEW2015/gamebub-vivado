#include "gbsdram_example_setup.h"
int main(void) {
#ifdef GBSDRAM_EXAMPLE_ARMED
 GBSdram s;GBSdram_Reservation r;u32 fail=0;int rc=setup(&s,&r);
 if(rc==XST_SUCCESS)rc=GBSdram_ScratchTest(&s,&r,&fail);
 xil_printf(rc==XST_SUCCESS?"GBSDRAM_SCRATCH_PASS\r\n":"GBSDRAM_SCRATCH_FAIL\r\n");return rc;
#else
 xil_printf("GBSDRAM_SCRATCH_DISABLED: reserve scratch and confirm BRAM/client safety\r\n");return XST_FAILURE;
#endif
}
