/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbaudio.c
 * @brief Bounded FPGA test-tone configuration, playback and heartbeat control.
 *
 * License details: LICENSE.md at repository root.
 */
#include <stddef.h>
#include "xil_io.h"
#include "gbaudio.h"

static int Ready(const GBAudio *I)
{
    return I != NULL && I->IsReady == 1U;
}

static u32 Read(const GBAudio *I, u32 O)
{
    return Xil_In32(I->Config.BaseAddress + O);
}

static void Write(const GBAudio *I, u32 O, u32 V)
{
    Xil_Out32(I->Config.BaseAddress + O, V);
}

int GBAudio_CfgInitialize(GBAudio *I, const GBAudio_Config *C, UINTPTR A)
{
    if (I == NULL || C == NULL || A == 0U || (A & 3U) != 0U)
        return XST_INVALID_PARAM;
    I->IsReady = 0U;
    I->Config = *C;
    I->Config.BaseAddress = A;
    I->ClockHz = 0U;
    if (Read(I, GBAUDIO_ID_OFFSET) != GBAUDIO_DEVICE_ID)
        return XST_FAILURE;
    /* This is configured nominal MCLK, not a measured frequency. Reject an
     * incompatible image without starting or stopping a running tone. */
    I->ClockHz = Read(I, GBAUDIO_CLOCK_OFFSET);
    if (I->ClockHz != GBAUDIO_NOMINAL_CLOCK_HZ)
        return XST_FAILURE;
    I->IsReady = 1U;
    return XST_SUCCESS;
}

int GBAudio_SelfTest(const GBAudio *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    return Read(I, GBAUDIO_ID_OFFSET) == GBAUDIO_DEVICE_ID ? XST_SUCCESS : XST_FAILURE;
}

u32 GBAudio_Status(const GBAudio *I)
{
    return Ready(I) ? Read(I, GBAUDIO_STATUS_OFFSET) : 0U;
}

int GBAudio_Configure(const GBAudio *I, const GBAudio_Tone *T)
{
    if (!Ready(I) || T == NULL || T->FrequencyHz < 20U || T->FrequencyHz > 12000U ||
        T->LevelPercent > 100U || T->Waveform > 2U || T->Channels > 2U || T->LimitMs < 100U ||
        T->LimitMs > 30000U)
        return XST_INVALID_PARAM;
    if (GBAudio_Status(I) & GBAUDIO_RUNNING)
        return XST_FAILURE;
    /* Level is FPGA PCM amplitude, not the ESP32-controlled DAC analog volume. */
    Write(I, GBAUDIO_FREQUENCY_OFFSET, T->FrequencyHz);
    Write(I, GBAUDIO_LEVEL_OFFSET, T->LevelPercent);
    Write(I, GBAUDIO_WAVEFORM_OFFSET, T->Waveform);
    Write(I, GBAUDIO_CHANNELS_OFFSET, T->Channels);
    Write(I, GBAUDIO_LIMIT_OFFSET, T->LimitMs);
    return XST_SUCCESS;
}

int GBAudio_Start(const GBAudio *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    if (GBAudio_Status(I) & GBAUDIO_RUNNING)
        return XST_FAILURE;
    /* Validate live config; another AXI writer must not race this sequence. */
    if (Read(I, GBAUDIO_FREQUENCY_OFFSET) < 20U || Read(I, GBAUDIO_FREQUENCY_OFFSET) > 12000U ||
        Read(I, GBAUDIO_LEVEL_OFFSET) > 100U || Read(I, GBAUDIO_WAVEFORM_OFFSET) > 2U ||
        Read(I, GBAUDIO_CHANNELS_OFFSET) > 2U || Read(I, GBAUDIO_LIMIT_OFFSET) < 100U ||
        Read(I, GBAUDIO_LIMIT_OFFSET) > 30000U)
        return XST_INVALID_PARAM;
    Write(I, GBAUDIO_COMMAND_OFFSET, GBAUDIO_START);
    return XST_SUCCESS;
}

int GBAudio_Stop(const GBAudio *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    Write(I, GBAUDIO_COMMAND_OFFSET, GBAUDIO_STOP);
    return XST_SUCCESS;
}

int GBAudio_Heartbeat(const GBAudio *I)
{
    if (!Ready(I))
        return XST_INVALID_PARAM;
    /* Refresh the short lease without extending the independent session limit. */
    Write(I, GBAUDIO_HEARTBEAT_OFFSET, GBAUDIO_HEARTBEAT_KEY);
    return XST_SUCCESS;
}

double GBAudio_SampleRate(const GBAudio *I)
{
    return Ready(I) ? (double)I->ClockHz / 608.0 : 0.0;
}
