/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file audio_tone.c
 * @brief Request a bounded low-level tone, then explicitly stop it.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbaudio.h"

/** Deliberate opt-in bounded250ms tone, 5% digital amplitude. No busy wait.
 * stop_n must be released and ESP32 must configure the external DAC first.
 * Hardware250ms bound is shorter than500ms lease; no heartbeat is required.
 * Caller must explicitly invoke this function; initialization never plays. */
int GBAudio_ToneExample(GBAudio *I)
{
    const GBAudio_Tone T = {440U, 5U, GBAUDIO_SINE, GBAUDIO_BOTH, 250U};
    int S;
    S = GBAudio_Stop(I);
    if (S)
        return S;
    /* Return to main loop for stop to propagate before configuring/starting. */
    if (GBAudio_Status(I) & GBAUDIO_RUNNING)
        return XST_FAILURE;
    S = GBAudio_Configure(I, &T);
    if (S)
        return S;
    return GBAudio_Start(I);
}
#ifndef TESTAPP_GEN
#include "xil_printf.h"

int main(void)
{
    GBAudio I;
    GBAudio_Config *C = GBAudio_LookupConfig(0U);
    int S;
    if (C == 0)
        return XST_FAILURE;
    S = GBAudio_CfgInitialize(&I, C, C->BaseAddress);
    if (S)
        return S;
    /* Deliberate build-time opt-in: default never plays on launch. */
#ifdef GBAUDIO_ENABLE_AUDIBLE_EXAMPLE
    S = GBAudio_ToneExample(&I);
#else
    S = GBAudio_SelfTest(&I);
#endif
    xil_printf("Audio status=%d; audible example requires explicit build opt-in\r\n", S);
    return S;
}
#endif
