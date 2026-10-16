/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* Compact BRAM-resident tester. No framebuffer or fixed platform addresses.
 * ESP32 owns its higher-priority menu layer; only the CPU layer is written.
 */
#include "platform_bindings.h"
#include "gbesp32.h"
#include "gbaudio.h"
#include "gbsram.h"
#include "gbsdram.h"
#include "xgpio_l.h"
#ifndef GAMEBUB_APP_TESTER_HOST
#include "xv_tpg_hw.h"
#endif
#include "xil_cache.h"
#include "xil_printf.h"
#include "sleep.h"

enum { AT_SRAM, AT_AUDIO, AT_VIBRATION, AT_SDRAM, AT_COUNT };
enum { AT_READY, AT_RUNNING, AT_PASS, AT_FAIL, AT_STOPPED, AT_GUARDED };
static GBEsp32 at_esp;
static GBAudio at_audio;
static GBSram at_sram;
static GBSdram at_sdram;
static unsigned at_page, at_state, at_progress, at_remaining, at_cursor;
static unsigned at_raw_last, at_stable, at_previous, at_debounce;
static unsigned at_dirty=1, at_release=1;
/* Same compact font and logical layout as the hardware-tested basic apps. */
static const u8 at_letters[26][7]={
 {14,17,17,31,17,17,17},{30,17,17,30,17,17,30},{15,16,16,16,16,16,15},
 {30,17,17,17,17,17,30},{31,16,16,30,16,16,31},{31,16,16,30,16,16,16},
 {15,16,16,23,17,17,15},{17,17,17,31,17,17,17},{31,4,4,4,4,4,31},
 {7,2,2,2,2,18,12},{17,18,20,24,20,18,17},{16,16,16,16,16,16,31},
 {17,27,21,21,17,17,17},{17,25,21,19,17,17,17},{14,17,17,17,17,17,14},
 {30,17,17,30,16,16,16},{14,17,17,17,21,18,13},{30,17,17,30,20,18,17},
 {15,16,16,14,1,1,30},{31,4,4,4,4,4,4},{17,17,17,17,17,17,14},
 {17,17,17,17,17,10,4},{17,17,17,21,21,21,10},{17,17,10,4,10,17,17},
 {17,17,10,4,4,4,4},{31,1,2,4,8,16,31}
};
static const u8 at_digits[10][7]={
 {14,17,19,21,25,17,14},{4,12,4,4,4,4,14},{14,17,1,2,4,8,31},
 {30,1,1,14,1,1,30},{2,6,10,18,31,2,2},{31,16,16,30,1,1,30},
 {14,16,16,30,17,17,14},{31,1,2,4,8,8,8},{14,17,17,14,17,17,14},
 {14,17,17,15,1,1,14}
};
struct at_label { unsigned x,y; const char *s; };
static unsigned at_ink(unsigned x,unsigned y,const struct at_label *label) {
 if(x<label->x || y<label->y || y>=label->y+7)return 0;
 unsigned col=(x-label->x)%6, index=(x-label->x)/6;
 const char *s=label->s;
 while(index && *s){++s;--index;}
 if(!*s || index || col>=5)return 0;
 unsigned c=(unsigned char)*s,row=0;
 if(c>='A' && c<='Z')row=at_letters[c-'A'][y-label->y];
 else if(c>='0' && c<='9')row=at_digits[c-'0'][y-label->y];
 else if(c=='-' && y==label->y+3)row=31;
 return (row>>(4-col))&1U;
}
static unsigned at_pixel(unsigned x,unsigned y,const struct at_label *labels,unsigned count) {
 if(x<96 || x>=288 || y<48 || y>=192)return 0; /* transparent */
 unsigned ink=x==96 || x==287 || y==48 || y==191;
 ink|=x>=104 && x<280 && (y==84 || y==147 || y==156);
 ink|=y>=147 && y<=156 && (x==104 || x==279);
 ink|=y>=150 && y<154 && x>=106 && x<106+at_progress*172/100;
 for(unsigned i=0;i<count && !ink;i++)ink=at_ink(x,y,labels+i);
 return ink?3:2; /* white ink or opaque black center */
}
static int at_draw(void) {
 static const char *names[]={"SRAM","AUDIO","VIBRATION","SDRAM"};
 static const char *states[]={"READY","RUNNING","PASS","FAIL","STOPPED","GUARDED - SEE SETTINGS"};
 const char *detail=at_page==AT_AUDIO?"440 HZ - 5 PERCENT - 250 MS":
   at_page==AT_VIBRATION?"FORWARD PULSE - 100 MS":"SCRATCH TEST - OVERWRITES";
 static struct at_label labels[]={{171,58,"GAMEBUB"},{159,70,"VIVADO FLOW"},
   {104,94,0},{104,108,0},{104,122,0},
   {104,134,"NOT A TIMING QUALIFICATION"},{104,164,"L R CHANGE APP"},{104,178,"A START   B STOP"}};
 labels[2].s=names[at_page];labels[3].s=detail;labels[4].s=states[at_state];
 /* One packed scanline: 96 bytes, rather than an 11-KiB shadow framebuffer. */
 u32 words[24];
 for(unsigned y=0;y<240;y++) {
   for(unsigned w=0;w<24;w++) {
     u32 packed=0;
     for(unsigned lane=0;lane<16;lane++)packed|=at_pixel(w*16+lane,y,labels,8)<<(lane*2);
     words[w]=packed;
   }
   if(GBEsp32_OverlayWords(&at_esp,y*24,words,24))return XST_FAILURE;
 }
 return GBEsp32_OverlayEnable(&at_esp,1);
}
static void at_off(void) {
 XGpio_WriteReg(GB_VIBRATION_BASE,XGPIO_DATA_OFFSET,0);
 (void)GBAudio_Stop(&at_audio);
 at_remaining=0;
}
static void at_stop(void) {
 at_off();
 if(at_state==AT_RUNNING)at_state=AT_STOPPED;
 at_dirty=1;
}
static void at_start(void) {
 at_off();at_progress=0;at_cursor=0;
 if(at_page==AT_AUDIO) {
   GBAudio_Tone tone={440,5,0,0,250};
   int rc=GBAudio_Configure(&at_audio,&tone);
   if(!rc)rc=GBAudio_Heartbeat(&at_audio);
   if(!rc)rc=GBAudio_Start(&at_audio);
   at_state=rc?AT_FAIL:AT_RUNNING;at_remaining=rc?0:250;
 } else if(at_page==AT_VIBRATION) {
   /* Complete the slow UI upload BEFORE starting the software-bounded motor. */
   at_state=AT_RUNNING;
   if(at_draw()){at_state=AT_FAIL;at_dirty=1;return;}
   XGpio_WriteReg(GB_VIBRATION_BASE,XGPIO_DATA_OFFSET,1);at_remaining=100;at_dirty=0;return;
 } else {
#if GB_ALLOW_DESTRUCTIVE && GB_BRAM_EXECUTION_CONFIRMED && GB_SCRATCH_BYTES > 0
   u32 size=at_page==AT_SRAM?GB_SRAM_MEMORY_SIZE:GB_SDRAM_MEMORY_SIZE;
   if((GB_SCRATCH_OFFSET&3U) || (GB_SCRATCH_BYTES&3U) ||
      GB_SCRATCH_OFFSET>=size || GB_SCRATCH_BYTES>size-GB_SCRATCH_OFFSET) {
     at_state=AT_FAIL;at_dirty=1;return;
   }
   Xil_DCacheFlush();Xil_DCacheDisable();
   int rc=at_page==AT_SRAM?GBSram_WaitReady(&at_sram,100000):
     GBSdram_SetOwner(&at_sdram,GBSDRAM_OWNER_CPU,100000);
   at_state=rc?AT_FAIL:AT_RUNNING;
#else
   at_state=AT_GUARDED; /* Never label an unexecuted test PASS. */
#endif
 }
 at_dirty=1;
}
static void at_memory_step(void) {
#if GB_ALLOW_DESTRUCTIVE && GB_BRAM_EXECUTION_CONFIRMED && GB_SCRATCH_BYTES > 0
 u32 bytes=GB_SCRATCH_BYTES-at_cursor,fail=0;
 if(bytes>256)bytes=256;
 int rc;
 if(at_page==AT_SRAM) {
   GBSram_Reservation r={GB_SCRATCH_OFFSET+at_cursor,bytes,1,1};
   rc=GBSram_ScratchTest(&at_sram,&r,&fail);
 } else {
   GBSdram_Reservation r={GB_SCRATCH_OFFSET+at_cursor,bytes,1,1};
   rc=GBSdram_ScratchTest(&at_sdram,&r,&fail);
 }
 if(rc){at_state=AT_FAIL;at_dirty=1;print("Scratch test FAIL\r\n");return;}
 at_cursor+=bytes;
 /* Runtime range validation caps bytes at 32 MiB: *100 fits in u32.
  * Avoid pulling 64-bit arithmetic helpers into this RV32I image. */
 unsigned progress=at_cursor*100U/GB_SCRATCH_BYTES;
 if(progress/5!=at_progress/5){at_progress=progress;at_dirty=1;}
 if(at_cursor==GB_SCRATCH_BYTES){at_progress=100;at_state=AT_PASS;at_dirty=1;}
#endif
}
/* Register order is reversed relative to the board/native button bitmap. */
static unsigned at_buttons(unsigned host) {
 unsigned raw=0;for(unsigned i=0;i<12;i++)raw|=((host>>i)&1U)<<(11-i);
 return raw;
}
static void at_tick(unsigned raw) {
 if(raw==at_raw_last){if(at_debounce<8)++at_debounce;}
 else {at_raw_last=raw;at_debounce=0;}
 if(at_debounce>=8)at_stable=raw;
 unsigned pressed=at_stable&~at_previous;at_previous=at_stable;
 if(raw&2){at_stop();at_release=1;}
 else if(pressed&0x300) {
   at_stop();at_page=(at_page+((pressed&0x100)?AT_COUNT-1:1))%AT_COUNT;
   at_state=AT_READY;at_progress=0;at_release=1;
 } else if((pressed&1) && !at_release && at_state!=AT_RUNNING)at_start();
 if(!(raw&3) && !(at_stable&3))at_release=0;
 if(at_state==AT_RUNNING) {
   if(at_page==AT_SRAM || at_page==AT_SDRAM)at_memory_step();
   else if(at_remaining && !--at_remaining){at_off();at_state=AT_PASS;at_progress=100;at_dirty=1;}
 }
 /* No rendering while an actuator is active: slow MMIO must not extend it. */
 if(at_dirty && (at_state!=AT_RUNNING || at_page==AT_SRAM || at_page==AT_SDRAM)) {
   if(at_draw())at_state=AT_FAIL;
   at_dirty=0;
 }
}
#ifndef GAMEBUB_APP_TESTER_HOST
int main(void) {
 /* Native CMake has already resolved one unambiguous instance per class.
  * Initialize from those generated addresses rather than linking four
  * runtime name tables/searches. CfgInitialize still checks device IDs/ABI. */
 GBEsp32_Config ec={0,GB_ESP32_BASE};
 GBAudio_Config ac={0,GB_AUDIO_BASE};
 GBSram_Config sc={0,GB_SRAM_CTRL_BASE};
 GBSdram_Config dc={0,GB_SDRAM_CTRL_BASE};
 /* The native metadata gate requires one two-bit all-output GPIO. The
  * low-level AMD register API avoids linking general-purpose GPIO setup. */
 XGpio_WriteReg(GB_VIBRATION_BASE,XGPIO_DATA_OFFSET,0);
 XGpio_WriteReg(GB_VIBRATION_BASE,XGPIO_TRI_OFFSET,0);
 if(GBAudio_CfgInitialize(&at_audio,&ac,ac.BaseAddress))return XST_FAILURE;
 at_off();
 if(GBEsp32_CfgInitialize(&at_esp,&ec,ec.BaseAddress) ||
    GBSram_CfgInitialize(&at_sram,&sc,sc.BaseAddress) ||
    GBSdram_CfgInitialize(&at_sdram,&dc,dc.BaseAddress))return XST_FAILURE;
 if(GBSram_BindMemory(&at_sram,GB_SRAM_MEMORY_BASE,GB_SRAM_MEMORY_SIZE) ||
    GBSdram_BindMemory(&at_sdram,GB_SDRAM_MEMORY_BASE,GB_SDRAM_MEMORY_SIZE))return XST_FAILURE;
 /* Dimensions match the existing LCD sink. Clear unrelated TPG features so
  * reloading just the ELF cannot inherit another application's overlay. */
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_HEIGHT_DATA,800);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_WIDTH_DATA,480);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_COLORFORMAT_DATA,0);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_BCKGNDID_DATA,9);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_OVRLAYID_DATA,0);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_MASKID_DATA,0);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_ENABLEINPUT_DATA,0);
 Xil_Out32(GB_TPG_BASE+XV_TPG_CTRL_ADDR_AP_CTRL,0x81);
 if(at_draw())return XST_FAILURE;
 at_dirty=0;
 print("GameBub: L/R app, A start, B stop. Scratch tests overwrite reserved RAM.\r\n");
 for(;;){at_tick(at_buttons(GBEsp32_Buttons(&at_esp)));usleep(1000);}
}
#endif
