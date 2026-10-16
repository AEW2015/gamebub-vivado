/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include "gbesp32.h"
/** One bounded read-only poll. Platform main prints the returned bitmap. */
int GBEsp32_PollExample(UINTPTR BaseAddress,u32 *Buttons) {
    GBEsp32 I; GBEsp32_Config *C=GBEsp32_LookupConfig(BaseAddress); int S;
    if(C==0 || Buttons==0) return XST_INVALID_PARAM;
    S=GBEsp32_CfgInitialize(&I,C,C->BaseAddress);
    if(S!=XST_SUCCESS) return S;
    *Buttons=GBEsp32_Buttons(&I); return GBEsp32_SelfTest(&I);
}
#ifndef TESTAPP_GEN
#include "xil_printf.h"
int main(void) {
    u32 B=0U; int S=GBEsp32_PollExample(0U,&B);
    xil_printf("ESP32 poll status=%d buttons=0x%x\r\n",S,B); return S;
}
#endif
