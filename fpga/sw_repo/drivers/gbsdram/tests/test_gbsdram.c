#include "gbsdram.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#define CSR 0x40000000U
#define RAM 0x78000000U
static u32 regs[2048],ram[16],owner,writes,stall,passes=1;
u32 Xil_In32(UINTPTR a) {if(a>=CSR && a<CSR+8192)return regs[(a-CSR)/4];assert(a>=RAM && a<RAM+64);return ram[(a-RAM)/4];}
void Xil_Out32(UINTPTR a,u32 v) {
 writes++;
 if(a>=CSR && a<CSR+8192) {
  u32 o=(u32)(a-CSR);regs[o/4]=v;
  if(o==4 && !stall) {
   regs[3]++;regs[1]=0;
   if(v==GBSDRAM_SET_OWNER)owner=regs[0x4c/4]>>30;
   if(v==GBSDRAM_START){regs[0x118/4]++;regs[0x100/4]=0xc86U|(passes?0:8U);regs[0x10c/4]=32;regs[0x110/4]=32;regs[0x114/4]=passes?0:1;}
   if(v==GBSDRAM_LOAD_TAPS){regs[0x190/4]=regs[0x50/4];regs[0x194/4]=regs[0x54/4];regs[0x198/4]=regs[0x58/4];}
   regs[2]=owner<<2;
  }
  return;
 }
 assert(a>=RAM && a<RAM+64);ram[(a-RAM)/4]=v;
}
void Xil_Out8(UINTPTR a,u8 v){u32 *p=&ram[(a-RAM)/4],b=(a-RAM)%4;assert(a>=RAM && a<RAM+64);*p=(*p&~(255U<<(b*8)))|((u32)v<<(b*8));}
static int unsafe(void *r){(void)r;return 0;}
static int safe(void *r){(void)r;return 1;}
int main(void) {
 GBSdram s;GBSdram_Config c={"renamed",CSR};GBSdram_Reservation r={0,64,1,1};GBSdram_TestResult result;GBSdram_ClockProfile p;GBSdram_ClockStatus cs;u8 taps[16];u32 fail=0,o,m,d,previous=0;
 memset(regs,0,sizeof(regs));regs[0]=GBSDRAM_ID;regs[4]=GBSDRAM_BYTES;regs[5]=1;regs[1024]=GBSDRAM_CLOCK_ID;
 assert(GBSdram_CfgInitialize(&s,&c,CSR)==XST_SUCCESS && !writes);
 assert(GBSdram_SelfTest(&s)==XST_SUCCESS && !writes);
 assert(GBSdram_LookupConfig(CSR)==NULL);
 assert(GBSdram_BindMemory(&s,RAM,GBSDRAM_BYTES)==XST_SUCCESS);
 assert(GBSdram_SetOwner(&s,1,32)==XST_SUCCESS);assert(GBSdram_GetOwner(&s,&o,32)==XST_SUCCESS && o==1);
 assert(GBSdram_ScratchTest(&s,&r,&fail)==XST_SUCCESS);
 assert(GBSdram_RunTest(&s,&r,1,64,&result)==XST_SUCCESS);
 passes=0;assert(GBSdram_RunTest(&s,&r,1,64,&result)==XST_FAILURE);
 r.AllClientsParked=0;writes=0;assert(GBSdram_RunTest(&s,&r,1,64,&result)==XST_INVALID_PARAM && writes==0);r.AllClientsParked=1;
 r.Size=GBSDRAM_BYTES+4;assert(GBSdram_ScratchTest(&s,&r,&fail)==XST_INVALID_PARAM);r.Size=64;
 stall=1;assert(GBSdram_GetOwner(&s,&o,4)!=XST_SUCCESS);stall=0;
 /* Independently bound every selected profile across frequency range. */
 for(m=166000000;m<=250000000;m+=125000) {
  assert(GBSdram_CalculateClock(m,90000,&p)==XST_SUCCESS);
  d=p.D*p.O;assert(p.M8>=96*p.D && p.M8<=192*p.D && p.M8<=512);
  assert(6250*p.M8>=166000*d && 6250*p.M8<=250000*d);
  assert(p.ActualHz>=previous);previous=p.ActualHz;
  assert((p.SerialPhaseMilliDegrees*p.O+22500)/45000==(p.QuarterPhaseMilliDegrees*p.O*4+22500)/45000);
 }
 assert(GBSdram_CalculateClock(165999999,0,&p)==XST_INVALID_PARAM);
 assert(GBSdram_CalculateClock(250000000,360001,&p)==XST_INVALID_PARAM);
 assert(GBSdram_CalculateClock(200000000,90000,&p)==XST_SUCCESS && p.ActualHz==200000000);
 writes=0;assert(GBSdram_ApplyClock(&s,&p,unsafe,NULL,16)==XST_INVALID_PARAM && writes==0);
 assert(GBSdram_GetClockStatus(&s,&cs)==XST_SUCCESS && writes==0);
 for(o=0;o<16;o++)taps[o]=(u8)(2*o);
 assert(GBSdram_SetOwner(&s,0,32)==XST_SUCCESS);
 assert(GBSdram_LoadTaps(&s,taps,safe,NULL,64)==XST_SUCCESS);
 taps[3]=32;writes=0;assert(GBSdram_LoadTaps(&s,taps,safe,NULL,64)==XST_INVALID_PARAM && writes==0);
 regs[5]=2;assert(GBSdram_SelfTest(&s)==XST_FAILURE);
 puts("GBSDRAM_HOST_PASS identity ownership snapshots negative bounds clock-search safety");return 0;
}
