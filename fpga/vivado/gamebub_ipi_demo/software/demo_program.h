/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/* Each Vitis application defines GB_DEMO_KIND then includes this source.
 * Platform addresses below come from XSA, never from a fixed lab map.
 * Applications execute in local BRAM. Destructive examples require consent.
 */
#include "platform_bindings.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "sleep.h"
#include "xil_cache.h"
#include "gbesp32.h"
#include "gbaudio.h"
#include "gbsram.h"
#include "gbsdram.h"
#include "xgpio.h"
#include "xv_tpg.h"
#include "xintc.h"
#include "xil_exception.h"

#if GB_DEMO_KIND == 11
static volatile u32 event_count, last_buttons;
static void button_isr(void *ref) {
    GBEsp32 *esp = (GBEsp32 *)ref;
    last_buttons = GBEsp32_Buttons(esp);
    GBEsp32_IrqAcknowledge(esp);
    ++event_count;
}
#endif

int main(void) {
    int status = XST_SUCCESS;
    xil_printf("GameBub %s: software demo, not hardware qualification\r\n", GB_APP_NAME);
#if GB_DEMO_KIND == 1
    xil_printf("Hello over MDM JTAG UART; CPU %u Hz\r\n", GB_CPU_HZ);
#elif GB_DEMO_KIND == 2 || GB_DEMO_KIND == 3 || GB_DEMO_KIND == 4 || GB_DEMO_KIND == 11 || GB_DEMO_KIND == 12
    GBEsp32 esp;
    GBEsp32_Config *cfg = GBEsp32_LookupConfig(GB_ESP32_BASE);
    if (!cfg || (status = GBEsp32_CfgInitialize(&esp, cfg, cfg->BaseAddress))) return XST_FAILURE;
#if GB_DEMO_KIND == 2
    for (u32 i=0; i<100; ++i) {
        xil_printf("buttons=%03x pending=%u\r\n", GBEsp32_Buttons(&esp), GBEsp32_IrqPending(&esp));
        usleep(100000);
    }
#elif GB_DEMO_KIND == 3
    for (u32 i=0; i<16; ++i) {u32 value=0; status |= GBEsp32_Diagnostic(&esp,i,&value); xil_printf("diag[%u]=%08x\r\n",i,value);}
#elif GB_DEMO_KIND == 4 || GB_DEMO_KIND == 12
    status = GBEsp32_OverlayClear(&esp,0); /* transparent, not opaque black */
    for (u32 y=96;y<144 && !status;++y)
        for (u32 x=128;x<256 && !status;++x)
            status = GBEsp32_OverlayPixel(&esp,x,y,((x+y)&8)?3:2);
    if (!status) status = GBEsp32_OverlayEnable(&esp,1);
    xil_printf("CPU checker panel under ESP32 menus. Volume overlay should clear back.\r\n");
#if GB_DEMO_KIND == 12
    xil_printf("Composition demo: buttons + overlay; no automatic destructive or actuator tests.\r\n");
    for (u32 i=0;i<100;++i) {xil_printf("buttons=%03x\r\n",GBEsp32_Buttons(&esp));usleep(100000);}
#endif
#elif GB_DEMO_KIND == 11
    XIntc intc;
    status = XIntc_Initialize(&intc,GB_INTC_BASE);
    if (!status) status = XIntc_Connect(&intc,GB_ESP32_IRQ,button_isr,&esp);
    if (!status) status = XIntc_Start(&intc,XIN_REAL_MODE);
    if (status) return status;
    GBEsp32_IrqAcknowledge(&esp);
    XIntc_Enable(&intc,GB_ESP32_IRQ);
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,(Xil_ExceptionHandler)XIntc_InterruptHandler,&intc);
    Xil_ExceptionEnable();
    GBEsp32_IrqEnable(&esp,1);
    xil_printf("Press/release shoulder within 10s; no console writes in ISR.\r\n");
    for (u32 i=0;i<100;++i) usleep(100000);
    GBEsp32_IrqEnable(&esp,0); XIntc_Disable(&intc,GB_ESP32_IRQ); Xil_ExceptionDisable();
    xil_printf("events=%u last_buttons=%03x\r\n",event_count,last_buttons);
    if (!event_count) status = XST_FAILURE;
#endif
#elif GB_DEMO_KIND == 5 || GB_DEMO_KIND == 6
    XV_tpg tpg; XV_tpg_Config *cfg = XV_tpg_LookupConfig(GB_TPG_BASE);
    if (!cfg || (status=XV_tpg_CfgInitialize(&tpg,cfg,cfg->BaseAddress))) return XST_FAILURE;
    XV_tpg_Set_height(&tpg,800); XV_tpg_Set_width(&tpg,480);
    XV_tpg_Set_colorFormat(&tpg,0); /* RGB */
    XV_tpg_Set_bckgndId(&tpg,9); /* color bars */
    XV_tpg_EnableAutoRestart(&tpg); XV_tpg_Start(&tpg);
#if GB_DEMO_KIND == 6
    const u32 patterns[]={1,3,9};
    for (u32 i=0;i<3;++i) {XV_tpg_Set_bckgndId(&tpg,patterns[i]);usleep(1000000);}
#endif
    xil_printf("TPG configured; verify physical LCD separately.\r\n");
#elif GB_DEMO_KIND == 7
    GBAudio audio; GBAudio_Config *cfg=GBAudio_LookupConfig(GB_AUDIO_BASE);
    if (!cfg || (status=GBAudio_CfgInitialize(&audio,cfg,cfg->BaseAddress))) return XST_FAILURE;
    GBAudio_Stop(&audio); usleep(1000);
    GBAudio_Tone tone={440,5,0,0,250};
    status=GBAudio_Configure(&audio,&tone);
    if (!status) status=GBAudio_Heartbeat(&audio);
    if (!status) status=GBAudio_Start(&audio);
    if (!status) usleep(250000);
    GBAudio_Stop(&audio);
    xil_printf("Bounded tone command completed; this does not prove audible output.\r\n");
#elif GB_DEMO_KIND == 8
    XGpio gpio;
    status=XGpio_Initialize(&gpio,GB_VIBRATION_BASE);
    if (status) return status;
    XGpio_DiscreteWrite(&gpio,1,0); XGpio_SetDataDirection(&gpio,1,0);
    xil_printf("Motor forward/coast for 100ms; no independent GPIO watchdog.\r\n");
    XGpio_DiscreteWrite(&gpio,1,1); usleep(100000); XGpio_DiscreteWrite(&gpio,1,0);
#elif GB_DEMO_KIND == 9 || GB_DEMO_KIND == 13
    GBSram ram; GBSram_Config *cfg=GBSram_LookupConfig(GB_SRAM_CTRL_BASE);
    if (!cfg || (status=GBSram_CfgInitialize(&ram,cfg,cfg->BaseAddress))) return XST_FAILURE;
    status=GBSram_BindMemory(&ram,GB_SRAM_MEMORY_BASE,GB_SRAM_MEMORY_SIZE);
    if (!status) status=GBSram_SelfTest(&ram);
#if GB_DEMO_KIND == 13
    xil_printf("DESTRUCTIVE scratch requires GB_ALLOW_DESTRUCTIVE=1 and all clients parked.\r\n");
#if GB_ALLOW_DESTRUCTIVE && GB_BRAM_EXECUTION_CONFIRMED && GB_SCRATCH_BYTES > 0
    Xil_DCacheFlush(); Xil_DCacheDisable();
    GBSram_Reservation r={GB_SCRATCH_OFFSET,GB_SCRATCH_BYTES,1,1};u32 fail=0;
    if (!status) status=GBSram_WaitReady(&ram,1000000);
    if (!status) status=GBSram_ScratchTest(&ram,&r,&fail);
    xil_printf("scratch status=%d offset=%08x\r\n",status,fail);
#else
    status=XST_FAILURE;
#endif
#endif
#elif GB_DEMO_KIND == 10 || GB_DEMO_KIND == 14
    GBSdram ram; GBSdram_Config *cfg=GBSdram_LookupConfig(GB_SDRAM_CTRL_BASE);
    if (!cfg || (status=GBSdram_CfgInitialize(&ram,cfg,cfg->BaseAddress))) return XST_FAILURE;
    status=GBSdram_BindMemory(&ram,GB_SDRAM_MEMORY_BASE,GB_SDRAM_MEMORY_SIZE);
    if (!status) status=GBSdram_SelfTest(&ram);
#if GB_DEMO_KIND == 14
    xil_printf("DESTRUCTIVE scratch requires GB_ALLOW_DESTRUCTIVE=1 and all clients parked.\r\n");
#if GB_ALLOW_DESTRUCTIVE && GB_BRAM_EXECUTION_CONFIRMED && GB_SCRATCH_BYTES > 0
    Xil_DCacheFlush(); Xil_DCacheDisable();
    GBSdram_Reservation r={GB_SCRATCH_OFFSET,GB_SCRATCH_BYTES,1,1};u32 fail=0;
    if (!status) status=GBSdram_SetOwner(&ram,1,1000000);
    if (!status) status=GBSdram_ScratchTest(&ram,&r,&fail);
    xil_printf("scratch status=%d offset=%08x\r\n",status,fail);
#else
    status=XST_FAILURE;
#endif
#endif
#else
#error Unknown demo kind
#endif
    xil_printf("%s status=%d (software result only)\r\n",GB_APP_NAME,status);
    return status;
}
