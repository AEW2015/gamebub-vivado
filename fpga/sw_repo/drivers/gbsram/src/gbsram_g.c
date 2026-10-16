/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsram_g.c
 * @brief Fallback empty configuration table; Vitis SDT supplies discovered instances.
 *
 * License details: LICENSE.md at repository root.
 */
/* SDT generation replaces this empty table with discovered CSR instances. */
#include "gbsram.h"
#include <stddef.h>
GBSram_Config GBSram_ConfigTable[] = {{NULL, 0}};
