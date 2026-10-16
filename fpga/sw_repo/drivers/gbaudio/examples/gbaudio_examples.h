/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbaudio_examples.h
 * @brief Reusable bounded-tone and non-playing safety-probe entry points.
 *
 * License details: LICENSE.md at repository root.
 */
#ifndef GBAUDIO_EXAMPLES_H
#define GBAUDIO_EXAMPLES_H
#include "gbaudio.h"
int GBAudio_ToneExample(GBAudio *Instance);
int GBAudio_SafetyExample(GBAudio *Instance, u32 StopWhenRunning, u32 *Status);
#endif
