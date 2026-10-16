#ifndef GAMEBUB_HOST_XIL_IO_H
#define GAMEBUB_HOST_XIL_IO_H

#include "xil_types.h"

/* Tests provide these functions to model MMIO without touching hardware. */
u8 Xil_In8(UINTPTR Address);
u16 Xil_In16(UINTPTR Address);
u32 Xil_In32(UINTPTR Address);
void Xil_Out8(UINTPTR Address, u8 Value);
void Xil_Out16(UINTPTR Address, u16 Value);
void Xil_Out32(UINTPTR Address, u32 Value);

#endif
