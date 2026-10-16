/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsram_probe_example.c
 * @brief Read-only memory-core identity probe; does not test RAM cells.
 *
 * License details: LICENSE.md at repository root.
 */
/** Read-only probe; use generated configuration or an explicit reviewed base. */
#include "gbsram.h"
#include "xil_printf.h"

int main(void)
{
    GBSram s;
    GBSram_Config *cfg;
    int rc;
#ifdef GB_EXAMPLE_CTRL_BASE
    GBSram_Config manual = {"xsa_sram", GB_EXAMPLE_CTRL_BASE};
    cfg = GBSram_LookupConfig(GB_EXAMPLE_CTRL_BASE);
    if (!cfg)
        cfg = &manual;
#else
    cfg = GBSram_LookupConfig(0);
    /* Exact-address lookup APIs need the first generated table entry explicitly.
     * The checked-in empty table has Name=NULL, so it never invents a device. */
    if (!cfg && GBSram_ConfigTable[0].Name)
        cfg = &GBSram_ConfigTable[0];
#endif
    if (!cfg) {
        xil_printf("GBSRAM_CONFIG_REQUIRED: no generated CSR instance\r\n");
        return XST_FAILURE;
    }
    rc = GBSram_CfgInitialize(&s, cfg, cfg->BaseAddress);
    if (rc == XST_SUCCESS)
        rc = GBSram_SelfTest(&s);
    xil_printf(rc == XST_SUCCESS ? "GBSRAM_PROBE_PASS (identity only)\r\n"
                                 : "GBSRAM_PROBE_FAIL\r\n");
    return rc;
}
