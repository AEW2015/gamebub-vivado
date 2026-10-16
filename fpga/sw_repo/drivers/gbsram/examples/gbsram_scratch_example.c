#include "gbsram_example_setup.h"
int main(void) {
#ifdef GBSRAM_EXAMPLE_ARMED
 GBSram s;GBSram_Reservation r;u32 fail=0;int rc=setup(&s,&r);
 if(rc==XST_SUCCESS)rc=GBSram_ScratchTest(&s,&r,&fail);
 xil_printf(rc==XST_SUCCESS?"GBSRAM_SCRATCH_PASS\r\n":"GBSRAM_SCRATCH_FAIL\r\n");return rc;
#else
 xil_printf("GBSRAM_SCRATCH_DISABLED: reserve scratch and confirm BRAM/client safety\r\n");return XST_FAILURE;
#endif
}
