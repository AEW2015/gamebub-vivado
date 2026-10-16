/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsram_sinit.c
 * @brief Find a BSP/SDT configuration-table entry by its control-register base address.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbsram.h"
#include <stddef.h>

GBSram_Config *GBSram_LookupConfig(UINTPTR base)
{
    GBSram_Config *c = GBSram_ConfigTable;
    while (c->Name) {
        if (c->BaseAddress == base)
            return c;
        ++c;
    }
    return NULL;
}
