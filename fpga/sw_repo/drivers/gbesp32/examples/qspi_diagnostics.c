/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include "gbesp32.h"
/** Read16 non-atomic endpoint counters without mutating diagnostic selector. */
int GBEsp32_DiagnosticsExample(GBEsp32 *I,u32 Values[16]) {
    u32 N; int S;
    if(Values==0) return XST_INVALID_PARAM;
    for(N=0;N<16;++N) { S=GBEsp32_Diagnostic(I,N,&Values[N]); if(S) return S; }
    return XST_SUCCESS;
}
#ifndef TESTAPP_GEN
#include "xil_printf.h"
int main(void) {
    GBEsp32 I; GBEsp32_Config *C=GBEsp32_LookupConfig(0U); u32 V[16],N; int S;
    if(C==0) return XST_FAILURE;
    S=GBEsp32_CfgInitialize(&I,C,C->BaseAddress); if(S) return S;
    S=GBEsp32_DiagnosticsExample(&I,V); if(S) return S;
    for(N=0;N<16;++N) xil_printf("diag[%d]=0x%x\r\n",N,V[N]);
    return XST_SUCCESS;
}
#endif
