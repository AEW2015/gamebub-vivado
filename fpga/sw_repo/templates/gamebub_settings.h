/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file gamebub_settings.h
 * @brief Conservative safety defaults for standalone Vitis examples.
 *
 * License details: LICENSE.md at repository root.
 */
#ifndef GAMEBUB_TEMPLATE_SETTINGS_H
#define GAMEBUB_TEMPLATE_SETTINGS_H
/* Build/import never runs the program. Deliberately running audio/vibration
 * actuates the board. Destructive memory programs remain disabled below.
 * Before opting in: verify the full MEM_AXI aperture, reserve the range,
 * park all other clients, execute only from BRAM and maintain caches.
 * These flags acknowledge preconditions; they do not park other masters.
 */
#ifndef GB_ALLOW_DESTRUCTIVE
#define GB_ALLOW_DESTRUCTIVE 0
#endif
#ifndef GB_BRAM_EXECUTION_CONFIRMED
#define GB_BRAM_EXECUTION_CONFIRMED 0
#endif
#ifndef GB_SCRATCH_OFFSET
#define GB_SCRATCH_OFFSET 0
#endif
#ifndef GB_SCRATCH_BYTES
#define GB_SCRATCH_BYTES 0
#endif
#ifndef GB_ALLOW_RETIMING
#define GB_ALLOW_RETIMING 0
#endif
#endif
