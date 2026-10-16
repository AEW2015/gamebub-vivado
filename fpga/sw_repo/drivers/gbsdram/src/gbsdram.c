/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsdram.c
 * @brief SDRAM mailbox commands, destructive tests and guarded MMCM/IDELAY controls.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbsdram.h"
#include "xil_io.h"
#include <stddef.h>
#define RD(S, O) Xil_In32((S)->Config.BaseAddress + (O))
#define WR(S, O, V) Xil_Out32((S)->Config.BaseAddress + (O), (V))

static int valid(const GBSdram *s)
{
    return s && s->IsReady;
}

static int reserved(GBSdram *s, const GBSdram_Reservation *r, u32 a)
{
    /* These flags acknowledge caller-managed safety; they do not park DMA or
     * flush caches. Check bounds using subtraction to avoid Offset + Size wrap. */
    return valid(s) && s->MemorySize == GBSDRAM_BYTES && r && r->AllClientsParked &&
           r->CacheMaintained && r->Size && !(r->Offset & (a - 1)) && !(r->Size & (a - 1)) &&
           r->Offset < s->MemorySize && r->Size <= s->MemorySize - r->Offset;
}

int GBSdram_CfgInitialize(GBSdram *s, const GBSdram_Config *c, UINTPTR base)
{
    if (!s || !c || !base || (base & 0x1fffU))
        return XST_INVALID_PARAM;
    s->IsReady = 0;
    s->Config = *c;
    s->Config.BaseAddress = base;
    s->MemorySize = 0;
    s->MemoryBaseAddress = 0;
    if (RD(s, 0) != GBSDRAM_ID || RD(s, 0x10) != GBSDRAM_BYTES || RD(s, 0x14) != 1 ||
        RD(s, 0x1000) != GBSDRAM_CLOCK_ID)
        return XST_FAILURE;
    s->IsReady = 1;
    return XST_SUCCESS;
}

int GBSdram_SelfTest(GBSdram *s)
{
    if (!valid(s))
        return XST_INVALID_PARAM;
    return RD(s, 0) == GBSDRAM_ID && RD(s, 0x10) == GBSDRAM_BYTES && RD(s, 0x14) == 1 &&
                   RD(s, 0x1000) == GBSDRAM_CLOCK_ID
               ? XST_SUCCESS
               : XST_FAILURE;
}

int GBSdram_BindMemory(GBSdram *s, UINTPTR base, u32 size)
{
    /* This binds MEM_AXI, not linker placement or CPU cache configuration. */
    if (!valid(s) || size != GBSDRAM_BYTES || (base & (GBSDRAM_BYTES - 1)) ||
        base > ((UINTPTR)-1) - (size - 1))
        return XST_INVALID_PARAM;
    s->MemoryBaseAddress = base;
    s->MemorySize = size;
    return XST_SUCCESS;
}

static int command(GBSdram *s, u32 op, u32 *budget)
{
    u32 seq;
    if (!valid(s) || !budget || !*budget)
        return XST_INVALID_PARAM;
    while (*budget) {
        --*budget;
        if (!(RD(s, 8) & 1U))
            break;
    }
    if (!*budget || (RD(s, 8) & 2U))
        return XST_FAILURE;
    /* A new response sequence is observable even if busy changes between polls.
     * Poll counts are not deadlines and cannot bound a stalled AXI transaction. */
    seq = RD(s, 12);
    WR(s, 4, op);
    while (*budget) {
        --*budget;
        if (RD(s, 12) != seq)
            return (RD(s, 4) & 3U) ? XST_FAILURE : XST_SUCCESS;
    }
    return XST_FAILURE;
}

int GBSdram_SetOwner(GBSdram *s, u32 owner, u32 budget)
{
    u32 cfg;
    if (!valid(s) || owner > 2 || !budget)
        return XST_INVALID_PARAM;
    cfg = RD(s, 0x4c);
    WR(s, 0x4c, (cfg & 0x3fffffffU) | (owner << 30));
    if (command(s, GBSDRAM_SET_OWNER, &budget) != XST_SUCCESS)
        return XST_FAILURE;
    return ((RD(s, 8) >> 2) & 3U) == owner ? XST_SUCCESS : XST_FAILURE;
}

int GBSdram_GetOwner(GBSdram *s, u32 *owner, u32 budget)
{
    if (!valid(s) || !owner || !budget)
        return XST_INVALID_PARAM;
    if (command(s, GBSDRAM_SNAPSHOT, &budget) != XST_SUCCESS)
        return XST_FAILURE;
    *owner = (RD(s, 8) >> 2) & 3U;
    return XST_SUCCESS;
}

int GBSdram_ScratchTest(GBSdram *s, const GBSdram_Reservation *r, u32 *fail)
{
    u32 i, p, v, owner;
    if (!reserved(s, r, 4) || !fail)
        return XST_INVALID_PARAM;
    if (GBSdram_GetOwner(s, &owner, 1024) != XST_SUCCESS || owner != GBSDRAM_OWNER_CPU)
        return XST_FAILURE;
    /* Destructive write/readback passes: zero, ones, byte offset, inverted offset.
     * FailOffset is meaningful only on mismatch; no original data is restored. */
    for (p = 0; p < 4; p++) {
        for (i = 0; i < r->Size; i += 4) {
            v = p == 0 ? 0U : p == 1 ? 0xffffffffU : p == 2 ? r->Offset + i : ~(r->Offset + i);
            Xil_Out32(s->MemoryBaseAddress + r->Offset + i, v);
        }
        for (i = 0; i < r->Size; i += 4) {
            v = p == 0 ? 0U : p == 1 ? 0xffffffffU : p == 2 ? r->Offset + i : ~(r->Offset + i);
            if (Xil_In32(s->MemoryBaseAddress + r->Offset + i) != v) {
                *fail = r->Offset + i;
                return XST_FAILURE;
            }
        }
    }
    for (i = 0; i < 4; i++) {
        UINTPTR a = s->MemoryBaseAddress + r->Offset;
        Xil_Out32(a, 0x11223344U);
        Xil_Out8(a + i, 0xa5U);
        v = (0x11223344U & ~(0xffU << (i * 8))) | (0xa5U << (i * 8));
        if (Xil_In32(a) != v) {
            *fail = r->Offset;
            return XST_FAILURE;
        }
    }
    return XST_SUCCESS;
}

int GBSdram_Abort(GBSdram *s, u32 budget)
{
    return command(s, GBSDRAM_ABORT, &budget);
}

int GBSdram_RunTest(GBSdram *s, const GBSdram_Reservation *r, u32 patterns, u32 budget,
                    GBSdram_TestResult *out)
{
    u32 cfg, old_run;
    if (!reserved(s, r, 16) || !patterns || (patterns & ~511U) || !budget || !out)
        return XST_INVALID_PARAM;
    /* TEST ownership excludes CPU RAM accesses. Do not implicitly restore CPU
     * ownership on timeout: the engine or its reply may still be outstanding. */
    if (GBSdram_SetOwner(s, GBSDRAM_OWNER_TEST, budget) != XST_SUCCESS)
        return XST_FAILURE;
    WR(s, 0x40, r->Offset / 2);
    WR(s, 0x44, r->Size / 2);
    WR(s, 0x48, 0x1d0f0000U | patterns);
    cfg = RD(s, 0x4c);
    WR(s, 0x4c, (cfg & 0x3fffffffU) | 0x80000000U);
    if (command(s, GBSDRAM_SNAPSHOT, &budget) != XST_SUCCESS)
        return XST_FAILURE;
    /* Distinguish this run from a previously completed snapshot. PASS also needs
     * the expected comparison count, terminal status and zero comparison errors. */
    old_run = RD(s, 0x118);
    if (command(s, GBSDRAM_START, &budget) != XST_SUCCESS)
        return XST_FAILURE;
    while (budget) {
        if (command(s, GBSDRAM_SNAPSHOT, &budget) != XST_SUCCESS)
            break;
        out->Status = RD(s, 0x100);
        out->Compared = RD(s, 0x10c);
        out->ExpectedCompares = RD(s, 0x110);
        out->Errors = RD(s, 0x114);
        out->RunId = RD(s, 0x118);
        if (out->RunId != old_run && (out->Status & 2U))
            return ((out->Status & 0x37eU) == 6U && !out->Errors &&
                    out->Compared == out->ExpectedCompares && out->Compared)
                       ? XST_SUCCESS
                       : XST_FAILURE;
    }
    /* Abort is bounded but may itself fail; do not silently restore CPU grant. */
    (void)GBSdram_Abort(s, 1024);
    return XST_FAILURE;
}

int GBSdram_CalculateClock(u32 hz, u32 phase, GBSdram_ClockProfile *out)
{
    u32 d, o, m, actual, error, best = 0xffffffffU, ticks;
    GBSdram_ClockProfile p = {0};
    if (!out || hz < 166000000U || hz > 250000000U || phase > 360000U)
        return XST_INVALID_PARAM;
    /* Enumerate legal MMCM ratios; M8 stores feedback multiplication in eighths.
     * The ABI's logical reference is 50 MHz, hence 6.25 MHz * M8 / (D * O).
     * This calculation is pure software; it does not reconfigure the device. */
    for (d = 1; d <= 5; d++)
        for (o = 3; o <= 7; o++)
            for (m = 96 * d; m <= 192 * d && m <= 512; m++) {
                u32 denom = d * o;
                if (6250U * m < 166000U * denom || 6250U * m > 250000U * denom)
                    continue;
                actual = (6250000U * m + denom / 2) / denom;
                error = actual > hz ? actual - hz : hz - actual;
                if (error < best) {
                    best = error;
                    p.M8 = m;
                    p.D = d;
                    p.O = o;
                    p.ActualHz = actual;
                }
            }
    if (!p.O)
        return XST_FAILURE;
    ticks = (phase * p.O + 22500U) / 45000U;
    /* Encode two phases with identical MMCM phase ticks; integer mdeg rounded. */
    p.SerialPhaseMilliDegrees = (ticks * 45000U + p.O / 2) / p.O;
    p.QuarterPhaseMilliDegrees = (ticks * 11250U + p.O / 2) / p.O;
    p.RequestedHz = hz;
    *out = p;
    return XST_SUCCESS;
}

int GBSdram_ApplyClock(GBSdram *s, const GBSdram_ClockProfile *p, GBSdram_SafetyCheck safe,
                       void *ref, u32 budget)
{
    u32 owner, seq, i, words[6], denom, t1, t2, status;
    if (!valid(s) || !p || !safe || !budget || !safe(ref))
        return XST_INVALID_PARAM;
    denom = p->D * p->O;
    if (p->D < 1 || p->D > 5 || p->O < 3 || p->O > 7 || p->M8 < 96 * p->D || p->M8 > 192 * p->D ||
        p->M8 > 512 || 6250 * p->M8 < 166000 * denom || 6250 * p->M8 > 250000 * denom ||
        p->SerialPhaseMilliDegrees > 360000 || p->QuarterPhaseMilliDegrees > 90000)
        return XST_INVALID_PARAM;
    t1 = (p->SerialPhaseMilliDegrees * p->O + 22500) / 45000;
    t2 = (p->QuarterPhaseMilliDegrees * p->O * 4 + 22500) / 45000;
    if (t1 != t2 || p->ActualHz != (6250000U * p->M8 + denom / 2) / denom)
        return XST_INVALID_PARAM;
    if (GBSdram_GetOwner(s, &owner, budget) != XST_SUCCESS || owner != GBSDRAM_OWNER_PARK)
        return XST_FAILURE;
    status = RD(s, 0x1004);
    if ((status & 0x11U) != 0x10U)
        return XST_FAILURE;
    words[0] = p->M8;
    words[1] = p->D;
    words[2] = p->O;
    words[3] = p->SerialPhaseMilliDegrees;
    words[4] = p->QuarterPhaseMilliDegrees;
    words[5] = p->RequestedHz / 1000;
    for (i = 0; i < 6; i++)
        WR(s, 0x1020 + 4 * i, words[i]);
    if (!safe(ref))
        return XST_FAILURE;
    /* Commit only after a second system-wide safety check. Reinitialization
     * invalidates RAM contents; keep clients parked even when applying succeeds. */
    seq = RD(s, 0x1008);
    WR(s, 0x1004, 1);
    while (budget--) {
        status = RD(s, 0x1004);
        if (RD(s, 0x1008) != seq)
            return (status & 0xff0bU) == 2U && RD(s, 0x1040) == p->ActualHz ? XST_SUCCESS
                                                                            : XST_FAILURE;
    }
    return XST_FAILURE;
}

int GBSdram_GetClockStatus(GBSdram *s, GBSdram_ClockStatus *out)
{
    if (!valid(s) || !out)
        return XST_INVALID_PARAM;
    out->Status = RD(s, 0x1004);
    out->Epoch = RD(s, 0x100c);
    out->NominalHz = RD(s, 0x1040);
    out->CommandKHz = RD(s, 0x1044);
    out->ReadKHz = RD(s, 0x1048);
    return XST_SUCCESS;
}

int GBSdram_LoadTaps(GBSdram *s, const u8 taps[16], GBSdram_SafetyCheck safe, void *ref, u32 budget)
{
    u32 words[3] = {0, 0, 0}, owner, i, k, b, actual;
    if (!valid(s) || !taps || !safe || !budget || !safe(ref))
        return XST_INVALID_PARAM;
    /* Pack 16 five-bit tap values into 80 bits. A field crossing a 32-bit word
     * boundary contributes to both words; the final word uses only 16 bits. */
    for (i = 0; i < 16; i++) {
        if (taps[i] > 31)
            return XST_INVALID_PARAM;
        k = (i * 5) / 32;
        b = (i * 5) % 32;
        words[k] |= (u32)taps[i] << b;
        if (b > 27)
            words[k + 1] |= (u32)taps[i] >> (32 - b);
    }
    if (GBSdram_GetOwner(s, &owner, budget) != XST_SUCCESS || owner != GBSDRAM_OWNER_PARK)
        return XST_FAILURE;
    for (i = 0; i < 3; i++)
        WR(s, 0x50 + 4 * i, words[i]);
    if (!safe(ref))
        return XST_FAILURE;
    if (command(s, GBSDRAM_LOAD_TAPS, &budget) != XST_SUCCESS)
        return XST_FAILURE;
    /* PHY loads and tap synchronization lag the immediate mailbox reply. */
    while (budget) {
        if (command(s, GBSDRAM_SNAPSHOT, &budget) != XST_SUCCESS)
            return XST_FAILURE;
        for (i = 0; i < 3; i++) {
            actual = RD(s, 0x190 + 4 * i);
            if (i == 2)
                actual &= 65535U;
            if (actual != words[i])
                break;
        }
        if (i == 3)
            return XST_SUCCESS;
    }
    return XST_FAILURE;
}
