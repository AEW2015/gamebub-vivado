#include "gbsdram_example_setup.h"
int main(void) {
#ifdef GBSDRAM_EXAMPLE_ARMED
 GBSdram s;GBSdram_Reservation r;GBSdram_TestResult result;int rc=setup(&s,&r);
 if(rc==XST_SUCCESS)rc=GBSdram_RunTest(&s,&r,511,10000000,&result);
 /* Do not resume RAM clients blindly after any failure. */
 if(rc==XST_SUCCESS)rc=GBSdram_SetOwner(&s,GBSDRAM_OWNER_CPU,1000000);
 xil_printf(rc==XST_SUCCESS?"GBSDRAM_TEST_PASS\r\n":"GBSDRAM_TEST_FAIL\r\n");return rc;
#else
 xil_printf("GBSDRAM_TEST_DISABLED: reserve scratch and confirm BRAM/client safety\r\n");return XST_FAILURE;
#endif
}
