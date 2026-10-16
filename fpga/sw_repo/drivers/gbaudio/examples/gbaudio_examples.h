/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#ifndef GBAUDIO_EXAMPLES_H
#define GBAUDIO_EXAMPLES_H
#include "gbaudio.h"
int GBAudio_ToneExample(GBAudio *Instance);
int GBAudio_SafetyExample(GBAudio *Instance,u32 StopWhenRunning,u32 *Status);
#endif
