/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsdram_sinit.c
 * @brief Find a BSP/SDT configuration-table entry by its control-register base address.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbsdram.h"
#include <stddef.h>

GBSdram_Config *GBSdram_LookupConfig(UINTPTR base)
{
    GBSdram_Config *c = GBSdram_ConfigTable;
    while (c->Name) {
        if (c->BaseAddress == base)
            return c;
        ++c;
    }
    return NULL;
}
