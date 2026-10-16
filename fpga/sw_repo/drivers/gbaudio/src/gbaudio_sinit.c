/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include <stddef.h>
#include "gbaudio.h"
GBAudio_Config *GBAudio_LookupConfig(UINTPTR A) {
    u32 N;
    for (N=0U;GBAudio_ConfigTable[N].Name!=NULL;++N)
        if (A==0U || GBAudio_ConfigTable[N].BaseAddress==A) return &GBAudio_ConfigTable[N];
    return NULL;
}
