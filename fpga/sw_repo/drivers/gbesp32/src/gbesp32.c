/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbesp32.c
 * @brief ESP32 register access, latched button IRQs and independent CPU overlay writes.
 *
 * License details: LICENSE.md at repository root.
 */
#include <stddef.h>
#include "xil_io.h"
#include "gbesp32.h"

static int Ready(const GBEsp32 *I)
{
    return I != NULL && I->IsReady == 1U;
}

static u32 Read(const GBEsp32 *I, u32 O)
{
    return Xil_In32(I->Config.BaseAddress + O);
}

static void Write(const GBEsp32 *I, u32 O, u32 V)
{
    Xil_Out32(I->Config.BaseAddress + O, V);
}

static int Overlay(const GBEsp32 *I)
{
    /* Capability bits alone are insufficient: check the COV2 runtime identity
     * before accessing a layer that may be omitted from the FPGA image. */
    return Ready(I) &&
           (I->Capabilities & GBESP32_CAP_CPU_OVERLAY_MASK) == GBESP32_CAP_CPU_OVERLAY_MASK &&
           Read(I, GBESP32_OVERLAY_ID_OFFSET) == GBESP32_OVERLAY_ID;
}

int GBEsp32_CfgInitialize(GBEsp32 *I, const GBEsp32_Config *C, UINTPTR A)
{
    if (I == NULL || C == NULL || A == 0U || (A & 3U) != 0U)
        return XST_INVALID_PARAM;
    /* Initialization is read-only: preserve pending events and both overlays. */
    I->IsReady = 0U;
    I->Config = *C;
    I->Config.BaseAddress = A;
    I->Capabilities = 0U;
    if (Read(I, GBESP32_ID_OFFSET) != GBESP32_DEVICE_ID ||
        Read(I, GBESP32_ABI_OFFSET) != GBESP32_ABI)
        return XST_FAILURE;
    I->Capabilities = Read(I, GBESP32_CAP_OFFSET);
    I->IsReady = 1U;
    return XST_SUCCESS;
}

int GBEsp32_SelfTest(const GBEsp32 *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    return Read(I, GBESP32_ID_OFFSET) == GBESP32_DEVICE_ID &&
                   Read(I, GBESP32_ABI_OFFSET) == GBESP32_ABI
               ? XST_SUCCESS
               : XST_FAILURE;
}

u32 GBEsp32_Buttons(const GBEsp32 *I)
{
    return Ready(I) ? Read(I, GBESP32_BUTTONS_OFFSET) & 0xFFFU : 0U;
}

u32 GBEsp32_IrqPending(const GBEsp32 *I)
{
    return Ready(I) ? Read(I, GBESP32_PENDING_OFFSET) & 1U : 0U;
}

int GBEsp32_IrqEnable(const GBEsp32 *I, u32 E)
{
    if (!Ready(I) || E > 1U)
        return XST_INVALID_PARAM;
    Write(I, GBESP32_IRQ_ENABLE_OFFSET, E);
    return XST_SUCCESS;
}

int GBEsp32_IrqAcknowledge(const GBEsp32 *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    /* Clear the CPU latch only; the ESP32-facing IRQ is separate. A concurrent
     * button change wins over this write-one-to-clear in hardware. */
    Write(I, GBESP32_PENDING_OFFSET, 1U);
    return XST_SUCCESS;
}

int GBEsp32_Diagnostic(const GBEsp32 *I, u32 S, u32 *V)
{
    if (!Ready(I) || V == NULL || S >= 16U)
        return XST_INVALID_PARAM;
    *V = Read(I, GBESP32_DIAG_BANK_OFFSET + 4U * S);
    return XST_SUCCESS;
}

int GBEsp32_OverlayEnable(const GBEsp32 *I, u32 E)
{
    if (!Ready(I) || E > 1U)
        return XST_INVALID_PARAM;
    if (!Overlay(I))
        return XST_FAILURE;
    Write(I, GBESP32_OVERLAY_ENABLE_OFFSET, E);
    return XST_SUCCESS;
}

int GBEsp32_OverlayPixel(const GBEsp32 *I, u32 X, u32 Y, u32 C)
{
    if (!Ready(I) || X >= GBESP32_WIDTH || Y >= GBESP32_HEIGHT || C > 3U)
        return XST_INVALID_PARAM;
    if (!Overlay(I))
        return XST_FAILURE;
    /* Serialize CPU/ISR writers across the index/data pair: it is not atomic. */
    Write(I, GBESP32_PIXEL_INDEX_OFFSET, Y * GBESP32_WIDTH + X);
    Write(I, GBESP32_PIXEL_DATA_OFFSET, C);
    return XST_SUCCESS;
}

int GBEsp32_OverlayWords(const GBEsp32 *I, u32 F, const u32 *W, u32 N)
{
    u32 K;
    if (!Ready(I) || W == NULL || F >= GBESP32_WORDS || N > GBESP32_WORDS - F)
        return XST_INVALID_PARAM;
    if (!Overlay(I))
        return XST_FAILURE;
    /* Data writes auto-increment the index. A word holds 16 low-to-high two-bit
     * pixel lanes; these writes never modify the ESP32-owned overlay buffer. */
    Write(I, GBESP32_WORD_INDEX_OFFSET, F);
    for (K = 0U; K < N; ++K)
        Write(I, GBESP32_WORD_DATA_OFFSET, W[K]);
    return XST_SUCCESS;
}

int GBEsp32_OverlayClear(const GBEsp32 *I, u32 C)
{
    u32 K, V;
    if (!Ready(I) || C > 3U)
        return XST_INVALID_PARAM;
    if (!Overlay(I))
        return XST_FAILURE;
    /* Replicate a pixel across 16 lanes. This live fill is not frame-atomic. */
    V = C * 0x55555555U;
    Write(I, GBESP32_WORD_INDEX_OFFSET, 0U);
    for (K = 0U; K < GBESP32_WORDS; ++K)
        Write(I, GBESP32_WORD_DATA_OFFSET, V);
    return XST_SUCCESS;
}
