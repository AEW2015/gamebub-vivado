/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include "gbaudio.h"
/** Read-only safety probe by default; explicit StopWhenRunning requests stop.
 * Physical stop_n, lease and duration tests require timed application actions;
 * this helper deliberately does not weaken watchdogs or busy-wait indefinitely. */
int GBAudio_SafetyExample(GBAudio *I,u32 StopWhenRunning,u32 *Status) {
    if(Status==0 || StopWhenRunning>1U) return XST_INVALID_PARAM;
    if(GBAudio_SelfTest(I)) return XST_FAILURE;
    *Status=GBAudio_Status(I);
    if(StopWhenRunning) return GBAudio_Stop(I);
    return XST_SUCCESS;
}
#ifndef TESTAPP_GEN
#include "xil_printf.h"
int main(void) {
    GBAudio I; GBAudio_Config *C=GBAudio_LookupConfig(0U); u32 Status; int S;
    if(C==0) return XST_FAILURE;
    S=GBAudio_CfgInitialize(&I,C,C->BaseAddress); if(S) return S;
    S=GBAudio_SafetyExample(&I,0U,&Status); if(S) return S;
    xil_printf("Audio safety probe status=0x%x (no playback started)\r\n",Status);
    return XST_SUCCESS;
}
#endif
