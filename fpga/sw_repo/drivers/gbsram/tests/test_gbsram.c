#include "gbsram.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#define CSR 0x40000000U
#define RAM 0x76000000U
static u32 regs[128],ram[16],writes;
u32 Xil_In32(UINTPTR a) {if(a>=CSR && a<CSR+512)return regs[(a-CSR)/4];assert(a>=RAM && a<RAM+64);return ram[(a-RAM)/4];}
void Xil_Out32(UINTPTR a,u32 v) {writes++;if(a>=CSR && a<CSR+512){regs[(a-CSR)/4]=v;return;}assert(a>=RAM && a<RAM+64);ram[(a-RAM)/4]=v;}
void Xil_Out8(UINTPTR a,u8 v) {u32 *p=&ram[(a-RAM)/4],b=(a-RAM)%4;assert(a>=RAM && a<RAM+64);*p=(*p&~(255U<<(b*8)))|((u32)v<<(b*8));}
int main(void) {
 GBSram s;GBSram_Config c={"renamed",CSR};GBSram_Reservation r={0,64,1,1};u32 fail=0;
 memset(regs,0,sizeof(regs));regs[0]=GBSRAM_ID;regs[4]=0x0003011f;regs[5]=262144;regs[6]=4;
 assert(GBSram_CfgInitialize(&s,&c,CSR)==XST_SUCCESS && writes==0);
 assert(GBSram_SelfTest(&s)==XST_SUCCESS && writes==0);
 assert(GBSram_LookupConfig(CSR)==NULL);
 assert(GBSram_BindMemory(&s,RAM,GBSRAM_BYTES)==XST_SUCCESS);
 assert(GBSram_BindMemory(&s,RAM,64)==XST_INVALID_PARAM);
 assert(GBSram_WaitReady(&s,4)==XST_SUCCESS);
 regs[6]=7;assert(GBSram_WaitReady(&s,4)!=XST_SUCCESS);regs[6]=4;
 assert(GBSram_ScratchTest(&s,&r,&fail)==XST_SUCCESS);
 r.CacheMaintained=0;writes=0;assert(GBSram_ScratchTest(&s,&r,&fail)==XST_INVALID_PARAM && writes==0);
 r.CacheMaintained=1;r.Offset=GBSRAM_BYTES-32;assert(GBSram_ScratchTest(&s,&r,&fail)==XST_INVALID_PARAM);
 r.Offset=0;r.Size=3;assert(GBSram_ScratchTest(&s,&r,&fail)==XST_INVALID_PARAM);
 regs[0]=0;assert(GBSram_SelfTest(&s)!=XST_SUCCESS);assert(GBSram_CfgInitialize(&s,&c,CSR)!=XST_SUCCESS && !s.IsReady);
 puts("GBSRAM_HOST_PASS identity reservation bounds byte-lanes busy negative");return 0;
}
