#include "gbsram_example_setup.h"
int main(void) {
#ifdef GBSRAM_EXAMPLE_ARMED
 GBSram s;GBSram_Reservation r;GBSram_TestResult result;int rc=setup(&s,&r);
 if(rc==XST_SUCCESS)rc=GBSram_RunTest(&s,&r,6,10000000,&result);
 xil_printf(rc==XST_SUCCESS?"GBSRAM_TEST_PASS\r\n":"GBSRAM_TEST_FAIL\r\n");return rc;
#else
 xil_printf("GBSRAM_TEST_DISABLED: reserve scratch and confirm BRAM/client safety\r\n");return XST_FAILURE;
#endif
}
