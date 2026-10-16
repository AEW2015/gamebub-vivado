/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsram_instruction_example.c
 * @brief Guarded RISC-V instruction-fetch smoke test from executable external RAM.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbsram_example_setup.h"
#include "xil_io.h"

int main(void)
{
#if defined(GBSRAM_EXAMPLE_ARMED) && defined(__riscv)
    GBSram s;
    GBSram_Reservation r;
    int rc = setup(&s, &r);
    UINTPTR a;
    if (rc != XST_SUCCESS)
        return rc;
    if ((r.Offset & 3U) || r.Size < 8 || r.Size > GBSRAM_BYTES || r.Offset > GBSRAM_BYTES - r.Size)
        return XST_INVALID_PARAM;
    a = s.MemoryBaseAddress + r.Offset;
    Xil_Out32(a, 0x02a00513U);     /* addi a0,zero,42 */
    Xil_Out32(a + 4, 0x00008067U); /* jalr zero,ra,0 */
    /* Publish instructions, then synchronize instruction fetch before calling
     * the tiny return-42 function. Main, stack and traps must remain in BRAM. */
    Xil_DCacheFlushRange(a, 8);
    Xil_ICacheInvalidateRange(a, 8);
    __asm__ volatile("fence rw,rw\nfence.i" ::: "memory");
    rc = ((int (*)(void))a)() == 42 ? XST_SUCCESS : XST_FAILURE;
    xil_printf(rc == XST_SUCCESS ? "GBSRAM_INSTRUCTION_PASS\r\n" : "GBSRAM_INSTRUCTION_FAIL\r\n");
    return rc;
#else
    xil_printf(
        "GBSRAM_INSTRUCTION_DISABLED: requires RISC-V, BRAM safety and executable scratch\r\n");
    return XST_FAILURE;
#endif
}
