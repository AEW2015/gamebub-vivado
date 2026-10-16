/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsdram_g.c
 * @brief Fallback empty configuration table; Vitis SDT supplies discovered instances.
 *
 * License details: LICENSE.md at repository root.
 */
/* SDT generation replaces this empty table with discovered CSR instances. */
#include "gbsdram.h"
#include <stddef.h>
GBSdram_Config GBSdram_ConfigTable[] = {{NULL, 0}};
