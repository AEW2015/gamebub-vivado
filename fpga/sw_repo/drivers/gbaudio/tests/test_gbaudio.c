/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include <assert.h>
#include <stddef.h>
#include <stdio.h>
#include "gbaudio.h"
#define BASE 0x10000000U
static u32 Reg[64],Writes;
GBAudio_Config GBAudio_ConfigTable[]={{"audio",BASE},{NULL,0U}};
u32 Xil_In32(UINTPTR A) { assert(A>=BASE && A<BASE+sizeof Reg); return Reg[(A-BASE)/4]; }
void Xil_Out32(UINTPTR A,u32 V) { assert(A>=BASE && A<BASE+sizeof Reg); ++Writes; Reg[(A-BASE)/4]=V; }
int main(void) {
    GBAudio I; GBAudio_Tone T={440,5,0,0,250}; u32 W;
    assert(GBAudio_LookupConfig(BASE)==&GBAudio_ConfigTable[0]);
    assert(GBAudio_LookupConfig(5)==NULL);
    assert(GBAudio_CfgInitialize(&I,&GBAudio_ConfigTable[0],BASE)==XST_FAILURE);
    Reg[0]=GBAUDIO_DEVICE_ID; Reg[GBAUDIO_CLOCK_OFFSET/4]=25000000U;
    assert(GBAudio_CfgInitialize(&I,&GBAudio_ConfigTable[0],BASE)==XST_FAILURE && Writes==0U);
    Reg[GBAUDIO_CLOCK_OFFSET/4]=29361979U;
    assert(GBAudio_CfgInitialize(&I,&GBAudio_ConfigTable[0],BASE)==0);
    assert(GBAudio_SelfTest(&I)==0 && Writes==0U);
    assert(GBAudio_SampleRate(&I)>48292.0 && GBAudio_SampleRate(&I)<48294.0);
    T.LevelPercent=101; assert(GBAudio_Configure(&I,&T)==XST_INVALID_PARAM && Writes==0U);
    T.LevelPercent=5; Reg[GBAUDIO_STATUS_OFFSET/4]=1;
    assert(GBAudio_Configure(&I,&T)==XST_FAILURE && Writes==0U);
    Reg[GBAUDIO_STATUS_OFFSET/4]=0;
    assert(GBAudio_Configure(&I,&T)==0 && Writes==5U);
    assert(GBAudio_Start(&I)==0 && Reg[GBAUDIO_COMMAND_OFFSET/4]==1);
    assert(GBAudio_Heartbeat(&I)==0 && Reg[GBAUDIO_HEARTBEAT_OFFSET/4]==GBAUDIO_HEARTBEAT_KEY);
    assert(GBAudio_Stop(&I)==0 && Reg[GBAUDIO_COMMAND_OFFSET/4]==2);
    Reg[GBAUDIO_FREQUENCY_OFFSET/4]=0; W=Writes;
    assert(GBAudio_Start(&I)==XST_INVALID_PARAM && Writes==W);
    puts("GBAUDIO_MOCK_MMIO_PASS id lookup no_start_init ranges running_guard start stop heartbeat");
    return 0;
}
