/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsdram_probe_example.c
 * @brief Read-only memory-core identity probe; does not test RAM cells.
 *
 * License details: LICENSE.md at repository root.
 */
/** Read-only identity probe using generated configuration or explicit base. */
#include "gbsdram.h"
#include "xil_printf.h"

int main(void)
{
    GBSdram s;
    GBSdram_Config *cfg;
    int rc;
#ifdef GB_EXAMPLE_CTRL_BASE
    GBSdram_Config manual = {"xsa_sdram", GB_EXAMPLE_CTRL_BASE};
    cfg = GBSdram_LookupConfig(GB_EXAMPLE_CTRL_BASE);
    if (!cfg)
        cfg = &manual;
#else
    cfg = GBSdram_LookupConfig(0);
    if (!cfg && GBSdram_ConfigTable[0].Name)
        cfg = &GBSdram_ConfigTable[0];
#endif
    if (!cfg) {
        xil_printf("GBSDRAM_CONFIG_REQUIRED: no generated CSR instance\r\n");
        return XST_FAILURE;
    }
    rc = GBSdram_CfgInitialize(&s, cfg, cfg->BaseAddress);
    if (rc == XST_SUCCESS)
        rc = GBSdram_SelfTest(&s);
    xil_printf(rc == XST_SUCCESS ? "GBSDRAM_PROBE_PASS (identity only)\r\n"
                                 : "GBSDRAM_PROBE_FAIL\r\n");
    return rc;
}
