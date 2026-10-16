#include "gbsdram_example_setup.h"
static int safety(void *ref) {(void)ref;return 1;}
int main(void) {
#if defined(GBSDRAM_EXAMPLE_ARMED) && defined(GB_ALLOW_RETIMING) && GB_ALLOW_RETIMING == 1
 GBSdram s;GBSdram_Reservation r;GBSdram_ClockProfile p;int rc=setup(&s,&r);
 if(rc==XST_SUCCESS)rc=GBSdram_CalculateClock(200000000,180000,&p);
 if(rc==XST_SUCCESS)rc=GBSdram_SetOwner(&s,GBSDRAM_OWNER_PARK,1000000);
 if(rc==XST_SUCCESS)rc=GBSdram_ApplyClock(&s,&p,safety,0,10000000);
 /* Remain PARKED: data is invalid and clients must not resume here. */
 if(rc==XST_SUCCESS)xil_printf("GBSDRAM_TIMING_APPLIED actualHz=%lu (not memory-test PASS)\r\n",(unsigned long)p.ActualHz);
 else xil_printf("GBSDRAM_TIMING_FAIL stay in BRAM\r\n");
 return rc;
#else
 (void)safety;xil_printf("GBSDRAM_TIMING_DISABLED: opt-in BRAM-only experiment\r\n");return XST_FAILURE;
#endif
}
