/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gbsram_hw.h
 * @brief Register offsets, capability masks and command encodings; not RAM addresses.
 *
 * License details: LICENSE.md at repository root.
 */
/* GameBub SRAM v1.6 register contract; see data/registers.json. */
#ifndef GBSRAM_HW_H
#define GBSRAM_HW_H
#define GBSRAM_ID 0x53524802U
#define GBSRAM_BYTES 0x80000U
#define GBSRAM_ID_OFFSET 0x00U
#define GBSRAM_COMMAND_OFFSET 0x04U
#define GBSRAM_STATUS_OFFSET 0x08U
#define GBSRAM_SEQUENCE_OFFSET 0x0CU
#define GBSRAM_CAPABILITIES_OFFSET 0x10U
#define GBSRAM_WORDS_OFFSET 0x14U
#define GBSRAM_OWNER_OFFSET 0x18U
#define GBSRAM_PROFILE_OFFSET 0x1CU
#define GBSRAM_CONFIG_OFFSET 0x20U
#define GBSRAM_ACTIVE_OFFSET 0x40U
#define GBSRAM_NORMAL_LO_OFFSET 0x60U
#define GBSRAM_NORMAL_HI_OFFSET 0x64U
#define GBSRAM_SNAPSHOT_OFFSET 0x100U
#define GBSRAM_START 1U
#define GBSRAM_STOP 2U
#define GBSRAM_APPLY 4U
#define GBSRAM_CLEAR 8U
#define GBSRAM_SNAPSHOT 16U
#define GBSRAM_ADOPT_PROFILE 32U
#define GBSRAM_RESTORE_PROFILE 64U
#endif
