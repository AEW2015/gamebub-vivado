/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include "gbesp32.h"
/** Tiny black/white cross on transparent background; never touches ESP buffer.
 * Clears92160 logical CPU pixels, so call only with exclusive CPU writer ownership. */
int GBEsp32_OverlayExample(GBEsp32 *I) {
    u32 N; int S=GBEsp32_OverlayEnable(I,0);
    if(S) return S;
    S=GBEsp32_OverlayClear(I,GBESP32_PIXEL_TRANSPARENT);
    if(S) return S;
    for(N=176;N<208;++N) {
        S=GBEsp32_OverlayPixel(I,N,120,GBESP32_PIXEL_WHITE); if(S) return S;
    }
    for(N=104;N<136;++N) {
        S=GBEsp32_OverlayPixel(I,192,N,GBESP32_PIXEL_WHITE); if(S) return S;
    }
    return GBEsp32_OverlayEnable(I,1);
}
#ifndef TESTAPP_GEN
#include "xil_printf.h"
int main(void) {
    GBEsp32 I; GBEsp32_Config *C=GBEsp32_LookupConfig(0U); int S;
    if(C==0) return XST_FAILURE;
    S=GBEsp32_CfgInitialize(&I,C,C->BaseAddress); if(S) return S;
    S=GBEsp32_OverlayExample(&I);
    xil_printf("COV2 cross status=%d; requires connected overlay stream\r\n",S);
    return S;
}
#endif
