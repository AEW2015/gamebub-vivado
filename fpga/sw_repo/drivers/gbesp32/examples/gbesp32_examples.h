/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#ifndef GBESP32_EXAMPLES_H
#define GBESP32_EXAMPLES_H
#include "gbesp32.h"
typedef struct { GBEsp32 *Device; volatile u32 Buttons,Events; } GBEsp32_ButtonContext;
int GBEsp32_PollExample(UINTPTR BaseAddress,u32 *Buttons);
int GBEsp32_DiagnosticsExample(GBEsp32 *Instance,u32 Values[16]);
int GBEsp32_OverlayExample(GBEsp32 *Instance);
void GBEsp32_ButtonHandler(void *Reference);
#endif
