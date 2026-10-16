#include "gbsdram_example_setup.h"
#include "xil_io.h"
int main(void) {
#if defined(GBSDRAM_EXAMPLE_ARMED) && defined(__riscv)
 GBSdram s;GBSdram_Reservation r;int rc=setup(&s,&r);UINTPTR a;
 if(rc!=XST_SUCCESS)return rc;
 if((r.Offset&3U) || r.Size<8 || r.Size>GBSDRAM_BYTES || r.Offset>GBSDRAM_BYTES-r.Size)return XST_INVALID_PARAM;
 a=s.MemoryBaseAddress+r.Offset;Xil_Out32(a,0x02a00513U);Xil_Out32(a+4,0x00008067U);
 Xil_DCacheFlushRange(a,8);Xil_ICacheInvalidateRange(a,8);
 __asm__ volatile("fence rw,rw\nfence.i" ::: "memory");
 rc=((int (*)(void))a)()==42?XST_SUCCESS:XST_FAILURE;
 xil_printf(rc==XST_SUCCESS?"GBSDRAM_INSTRUCTION_PASS\r\n":"GBSDRAM_INSTRUCTION_FAIL\r\n");return rc;
#else
 xil_printf("GBSDRAM_INSTRUCTION_DISABLED: requires RISC-V, BRAM safety and executable scratch\r\n");return XST_FAILURE;
#endif
}
