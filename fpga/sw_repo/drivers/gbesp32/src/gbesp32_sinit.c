/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
#include <stddef.h>
#include "gbesp32.h"
GBEsp32_Config *GBEsp32_LookupConfig(UINTPTR A) {
    u32 N;
    for (N=0U;GBEsp32_ConfigTable[N].Name!=NULL;++N)
        if (A==0U || GBEsp32_ConfigTable[N].BaseAddress==A) return &GBEsp32_ConfigTable[N];
    return NULL;
}
