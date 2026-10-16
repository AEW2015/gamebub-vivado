#include "gbsram.h"
#include "xil_io.h"
#include <stddef.h>
#define RD(S,O) Xil_In32((S)->Config.BaseAddress+(O))
#define WR(S,O,V) Xil_Out32((S)->Config.BaseAddress+(O),(V))
static int valid(const GBSram *s) { return s && s->IsReady; }
static int reserved(GBSram *s,const GBSram_Reservation *r,u32 alignment) {
 return valid(s) && s->MemorySize==GBSRAM_BYTES && r && r->AllClientsParked && r->CacheMaintained &&
 r->Size && !(r->Offset&(alignment-1U)) && !(r->Size&(alignment-1U)) &&
 r->Offset<s->MemorySize && r->Size<=s->MemorySize-r->Offset;
}
int GBSram_CfgInitialize(GBSram *s,const GBSram_Config *c,UINTPTR base) {
 if(!s || !c || !base || (base&3U))return XST_INVALID_PARAM;
 s->IsReady=0;s->Config=*c;s->Config.BaseAddress=base;s->MemorySize=0;s->MemoryBaseAddress=0;
 if(RD(s,GBSRAM_ID_OFFSET)!=GBSRAM_ID || RD(s,GBSRAM_WORDS_OFFSET)!=GBSRAM_BYTES/2U ||
    RD(s,GBSRAM_CAPABILITIES_OFFSET)!=0x0003011fU)return XST_FAILURE;
 s->IsReady=1;return XST_SUCCESS;
}
int GBSram_SelfTest(GBSram *s) {
 if(!valid(s))return XST_INVALID_PARAM;
 return RD(s,0)==GBSRAM_ID && RD(s,0x14)==262144U && RD(s,0x10)==0x0003011fU?XST_SUCCESS:XST_FAILURE;
}
int GBSram_BindMemory(GBSram *s,UINTPTR base,u32 size) {
 if(!valid(s) || size!=GBSRAM_BYTES || (base&(GBSRAM_BYTES-1U)) ||
    base>((UINTPTR)-1)-(size-1U))return XST_INVALID_PARAM;
 s->MemoryBaseAddress=base;s->MemorySize=size;return XST_SUCCESS;
}
int GBSram_WaitReady(GBSram *s,u32 budget) {
 if(!valid(s) || !budget)return XST_INVALID_PARAM;
 while(budget--) {
  u32 st=RD(s,GBSRAM_STATUS_OFFSET),owner=RD(s,GBSRAM_OWNER_OFFSET);
  if(st&8U)return XST_FAILURE;
  if((st&7U)==0 && (owner&7U)==4U)return XST_SUCCESS;
 }
 return XST_FAILURE;
}
int GBSram_ScratchTest(GBSram *s,const GBSram_Reservation *r,u32 *fail) {
 u32 i,p,v,b;
 if(!reserved(s,r,4) || !fail)return XST_INVALID_PARAM;
 if(GBSram_WaitReady(s,1)!=XST_SUCCESS)return XST_FAILURE;
 for(p=0;p<4;p++) {
  for(i=0;i<r->Size;i+=4) { v=p==0?0U:p==1?0xffffffffU:p==2?(r->Offset+i):~(r->Offset+i); Xil_Out32(s->MemoryBaseAddress+r->Offset+i,v); }
  for(i=0;i<r->Size;i+=4) { v=p==0?0U:p==1?0xffffffffU:p==2?(r->Offset+i):~(r->Offset+i); if(Xil_In32(s->MemoryBaseAddress+r->Offset+i)!=v){*fail=r->Offset+i;return XST_FAILURE;} }
 }
 /* All four byte enables, preserving the untouched lanes. */
 for(b=0;b<4;b++) { UINTPTR a=s->MemoryBaseAddress+r->Offset; Xil_Out32(a,0x11223344U);Xil_Out8(a+b,0xa5U);v=(0x11223344U&~(0xffU<<(b*8)))|(0xa5U<<(b*8));if(Xil_In32(a)!=v){*fail=r->Offset;return XST_FAILURE;} }
 return XST_SUCCESS;
}
static int snapshot(GBSram *s,u32 *budget) {
 u32 seq=RD(s,GBSRAM_SEQUENCE_OFFSET);WR(s,GBSRAM_COMMAND_OFFSET,GBSRAM_SNAPSHOT);
 while(*budget) {--*budget;if(RD(s,GBSRAM_SEQUENCE_OFFSET)!=seq)return XST_SUCCESS;}
 return XST_FAILURE;
}
int GBSram_RunTest(GBSram *s,const GBSram_Reservation *r,u32 pattern,u32 budget,GBSram_TestResult *out) {
 u32 cfg[8],i,old_completed,status;int rc=XST_FAILURE;
 if(!reserved(s,r,2) || pattern>8 || !budget || !out)return XST_INVALID_PARAM;
 if(GBSram_WaitReady(s,budget)!=XST_SUCCESS)return XST_FAILURE;
 for(i=0;i<8;i++)cfg[i]=RD(s,GBSRAM_ACTIVE_OFFSET+4*i);
 cfg[0]=r->Offset/2;cfg[1]=r->Size/2;cfg[2]=0x1d0f0000U|pattern;cfg[5]=0;cfg[6]=0;cfg[7]=0;
 for(i=0;i<8;i++)WR(s,GBSRAM_CONFIG_OFFSET+4*i,cfg[i]);
 WR(s,GBSRAM_COMMAND_OFFSET,GBSRAM_APPLY);
 /* Observe applied configuration, not just a transient busy bit. */
 while(budget) {--budget;if(RD(s,GBSRAM_ACTIVE_OFFSET)==cfg[0] && RD(s,GBSRAM_ACTIVE_OFFSET+4)==cfg[1] && RD(s,GBSRAM_ACTIVE_OFFSET+8)==cfg[2] && !(RD(s,GBSRAM_STATUS_OFFSET)&7U))break;}
 if(!budget)return XST_FAILURE;
 if(snapshot(s,&budget)!=XST_SUCCESS)return XST_FAILURE;
 old_completed=RD(s,GBSRAM_SNAPSHOT_OFFSET+5*4);
 WR(s,GBSRAM_COMMAND_OFFSET,GBSRAM_START);
 while(budget) {
  if(snapshot(s,&budget)!=XST_SUCCESS)break;
  status=RD(s,GBSRAM_SNAPSHOT_OFFSET);
  if(status&8U)break;
  if(RD(s,GBSRAM_SNAPSHOT_OFFSET+5*4)!=old_completed){rc=XST_SUCCESS;break;}
 }
 WR(s,GBSRAM_COMMAND_OFFSET,GBSRAM_STOP);
 if(GBSram_WaitReady(s,1024)!=XST_SUCCESS)rc=XST_FAILURE;
 /* Snapshot after stop, preserving cumulative failure semantics. */
 budget=1024;
 if(snapshot(s,&budget)!=XST_SUCCESS)return XST_FAILURE;
 out->Passes=RD(s,0x110);out->Completed=RD(s,0x114);out->Failures=RD(s,0x11c);out->Reads=RD(s,0x148);out->Writes=RD(s,0x14c);
 if(out->Failures)rc=XST_FAILURE;
 return rc;
}
