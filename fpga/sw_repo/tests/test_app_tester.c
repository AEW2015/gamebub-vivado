/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include <assert.h>
#include <stdio.h>
#include "gamebub_settings.h"
#define GAMEBUB_APP_TESTER_HOST
#include "app_tester.h"

static unsigned motor, audio, uploads, memory_calls, owner_calls, fail_audio;
static unsigned fail_memory;
void Xil_Out32(UINTPTR address,u32 value) {
 assert(address==GB_VIBRATION_BASE);motor=value;
}
int GBAudio_Stop(const GBAudio *a){(void)a;audio=0;return 0;}
int GBAudio_Configure(const GBAudio *a,const GBAudio_Tone *t){
 (void)a;assert(t->LevelPercent==5 && t->LimitMs==250);return fail_audio;
}
int GBAudio_Heartbeat(const GBAudio *a){(void)a;return 0;}
int GBAudio_Start(const GBAudio *a){(void)a;audio=1;return 0;}
int GBEsp32_OverlayWords(const GBEsp32 *e,u32 first,const u32 *words,u32 count){
 (void)e;(void)words;assert(!motor && !audio);assert(count==24 && first%24==0);
 ++uploads;return 0;
}
int GBEsp32_OverlayEnable(const GBEsp32 *e,u32 enabled){(void)e;assert(enabled==1);return 0;}
int GBSram_WaitReady(GBSram *s,u32 budget){(void)s;assert(budget);return 0;}
int GBSdram_SetOwner(GBSdram *s,u32 owner,u32 budget){
 (void)s;assert(owner==GBSDRAM_OWNER_CPU && budget);++owner_calls;return 0;
}
int GBSram_ScratchTest(GBSram *s,const GBSram_Reservation *r,u32 *fail){
 (void)s;assert(r->AllClientsParked && r->CacheMaintained && r->Size<=256);
#if GB_ALLOW_DESTRUCTIVE
 assert(r->Offset-GB_SCRATCH_OFFSET<GB_SCRATCH_BYTES);
 assert(r->Size<=GB_SCRATCH_BYTES-(r->Offset-GB_SCRATCH_OFFSET));
#else
 assert(!"Guarded app must never enter ScratchTest");
#endif
 ++memory_calls;*fail=r->Offset;return fail_memory;
}
int GBSdram_ScratchTest(GBSdram *s,const GBSdram_Reservation *r,u32 *fail){
 (void)s;return GBSram_ScratchTest(0,(const GBSram_Reservation *)r,fail);
}
void Xil_DCacheFlush(void){}
void Xil_DCacheDisable(void){}
void print(const char *s){(void)s;}

static void hold(unsigned raw,unsigned ticks){while(ticks--)at_tick(raw);}
static void press(unsigned raw){hold(raw,10);hold(0,10);}
int main(void){
 (void)at_sram;(void)at_sdram;
 assert(at_buttons(0x800)==1);assert(at_buttons(0x400)==2);
 assert(at_buttons(8)==0x100);assert(at_buttons(4)==0x200);
 at_tick(0); /* also exercises initial rendering */
 assert(uploads==240 && !memory_calls && !owner_calls); /* no auto-run */
 struct at_label label={110,100,"A"};
 assert(at_pixel(0,0,&label,1)==0);
 assert(at_pixel(100,100,&label,1)==2);
 assert(at_pixel(96,48,&label,1)==3);
 assert(at_pixel(111,100,&label,1)==3);
 hold(0x200,30);assert(at_page==AT_AUDIO); /* held shoulder only once */
 hold(0,10);press(1);assert(audio && at_state==AT_RUNNING);
 hold(0,260);assert(!audio && at_state==AT_PASS);
 press(0x200);assert(at_page==AT_VIBRATION);
 press(1);assert(motor==1);hold(0,110);assert(!motor && at_state==AT_PASS);
 press(1);assert(motor==1);at_tick(2);assert(!motor && at_state==AT_STOPPED);
 hold(0,10);press(1);assert(motor==1);
 press(0x200);assert(at_page==AT_SDRAM && !motor && !audio);
 press(1);
#if GB_ALLOW_DESTRUCTIVE
 hold(0,50);assert(at_state==AT_PASS && memory_calls && owner_calls==1);
 assert(at_progress==100);
 press(0x200);assert(at_page==AT_SRAM);
 fail_memory=1;press(1);assert(at_state==AT_FAIL);
 fail_memory=0;hold(1,9);assert(at_state==AT_RUNNING);
 unsigned stopped_at=memory_calls;at_tick(2);hold(0,10);
 assert(at_state==AT_STOPPED && memory_calls==stopped_at);
#else
 assert(at_state==AT_GUARDED && !memory_calls && !owner_calls);
 press(0x200);press(1);assert(at_page==AT_SRAM && at_state==AT_GUARDED);
#endif
 press(0x200);assert(at_page==AT_AUDIO);
 fail_audio=1;press(1);assert(!audio && at_state==AT_FAIL);
 puts("APP_TESTER_HOST_PASS");return 0;
}
