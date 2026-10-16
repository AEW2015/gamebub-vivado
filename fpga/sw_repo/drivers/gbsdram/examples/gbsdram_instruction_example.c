/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsdram_instruction_example.c
 * @brief Guarded RISC-V instruction-fetch smoke test from executable external RAM.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbsdram_example_setup.h"
#include "xil_io.h"

int main(void)
{
#if defined(GBSDRAM_EXAMPLE_ARMED) && defined(__riscv)
    GBSdram s;
    GBSdram_Reservation r;
    int rc = setup(&s, &r);
    UINTPTR a;
    if (rc != XST_SUCCESS)
        return rc;
    if ((r.Offset & 3U) || r.Size < 8 || r.Size > GBSDRAM_BYTES ||
        r.Offset > GBSDRAM_BYTES - r.Size)
        return XST_INVALID_PARAM;
    /* RV32 instructions: addi a0,zero,42; jalr zero,ra,0 (return to BRAM).
     * This proves a tiny fetch/return path, not whole-program execution safety. */
    a = s.MemoryBaseAddress + r.Offset;
    Xil_Out32(a, 0x02a00513U);
    Xil_Out32(a + 4, 0x00008067U);
    /* Publish written instructions to memory and discard any stale fetch lines. */
    Xil_DCacheFlushRange(a, 8);
    Xil_ICacheInvalidateRange(a, 8);
    __asm__ volatile("fence rw,rw\nfence.i" ::: "memory");
    rc = ((int (*)(void))a)() == 42 ? XST_SUCCESS : XST_FAILURE;
    xil_printf(rc == XST_SUCCESS ? "GBSDRAM_INSTRUCTION_PASS\r\n" : "GBSDRAM_INSTRUCTION_FAIL\r\n");
    return rc;
#else
    xil_printf(
        "GBSDRAM_INSTRUCTION_DISABLED: requires RISC-V, BRAM safety and executable scratch\r\n");
    return XST_FAILURE;
#endif
}
