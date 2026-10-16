/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include <assert.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "gbesp32.h"
#define BASE 0x10000000U
static u32 Reg[256],Writes,Pixels[GBESP32_PIXELS];
GBEsp32_Config GBEsp32_ConfigTable[]={{"esp",BASE},{"second",BASE+0x1000U},{NULL,0U}};
u32 Xil_In32(UINTPTR A) { assert(A>=BASE && A<BASE+sizeof Reg); return Reg[(A-BASE)/4]; }
void Xil_Out32(UINTPTR A,u32 V) {
    u32 O=(u32)(A-BASE),N,J; assert(O<sizeof Reg); ++Writes;
    if (O==GBESP32_WORD_DATA_OFFSET) {
        N=Reg[GBESP32_WORD_INDEX_OFFSET/4];
        for(J=0U;J<16U;++J) Pixels[N*16U+J]=(V>>(J*2U))&3U;
        Reg[GBESP32_WORD_INDEX_OFFSET/4]=(N+1U)%GBESP32_WORDS;
    } else if(O==GBESP32_PIXEL_DATA_OFFSET) {
        N=Reg[GBESP32_PIXEL_INDEX_OFFSET/4]; Pixels[N]=V&3U;
        Reg[GBESP32_PIXEL_INDEX_OFFSET/4]=(N+1U)%GBESP32_PIXELS;
    }
    if(O==GBESP32_PENDING_OFFSET) Reg[O/4]&=~(V&1U); else Reg[O/4]=V;
}
int main(void) {
    GBEsp32 I; u32 V,W[2]={0xAAAAAAAAU,0xFFFFFFFFU};
    memset(Reg,0,sizeof Reg); memset(&I,0,sizeof I);
    assert(GBEsp32_LookupConfig(0)==&GBEsp32_ConfigTable[0]);
    assert(GBEsp32_LookupConfig(BASE+0x1000U)==&GBEsp32_ConfigTable[1]);
    assert(GBEsp32_LookupConfig(5)==NULL);
    assert(GBEsp32_CfgInitialize(&I,&GBEsp32_ConfigTable[0],BASE)==XST_FAILURE);
    Reg[0]=GBESP32_DEVICE_ID; Reg[1]=GBESP32_ABI; Reg[2]=0xDFU;
    Reg[GBESP32_OVERLAY_ID_OFFSET/4]=GBESP32_OVERLAY_ID;
    assert(GBEsp32_CfgInitialize(&I,&GBEsp32_ConfigTable[0],BASE)==XST_SUCCESS);
    assert(GBEsp32_SelfTest(&I)==XST_SUCCESS && Writes==0U);
    Reg[GBESP32_BUTTONS_OFFSET/4]=0xF123U;
    assert(GBEsp32_Buttons(&I)==0x123U);
    Reg[GBESP32_PENDING_OFFSET/4]=1U;
    assert(GBEsp32_IrqPending(&I)==1U);
    assert(GBEsp32_IrqAcknowledge(&I)==0 && GBEsp32_IrqPending(&I)==0U);
    assert(GBEsp32_IrqEnable(&I,2)==XST_INVALID_PARAM);
    assert(GBEsp32_IrqEnable(&I,1)==0 && Reg[GBESP32_IRQ_ENABLE_OFFSET/4]==1U);
    Reg[GBESP32_DIAG_BANK_OFFSET/4+15]=42U;
    assert(GBEsp32_Diagnostic(&I,15,&V)==0 && V==42U);
    assert(GBEsp32_Diagnostic(&I,16,&V)==XST_INVALID_PARAM);
    assert(GBEsp32_OverlayPixel(&I,383,239,3)==0 && Pixels[92159]==3U);
    assert(GBEsp32_OverlayPixel(&I,384,239,3)==XST_INVALID_PARAM);
    assert(GBEsp32_OverlayWords(&I,5759,W,2)==XST_INVALID_PARAM);
    assert(GBEsp32_OverlayWords(&I,5758,W,2)==0 && Pixels[92128]==2U && Pixels[92159]==3U);
    assert(GBEsp32_OverlayClear(&I,0)==0 && Pixels[0]==0U && Pixels[92159]==0U);
    assert(GBEsp32_OverlayClear(&I,2)==0 && Pixels[0]==2U && Pixels[92159]==2U);
    I.Capabilities=7U; V=Writes;
    assert(GBEsp32_OverlayEnable(&I,1)==XST_FAILURE && Writes==V);
    puts("GBESP32_MOCK_MMIO_PASS id lookup irq bounds packing transparent opaque capability");
    return 0;
}
