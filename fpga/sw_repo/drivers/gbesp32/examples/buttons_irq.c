/* SPDX-License-Identifier: CERN-OHL-S-2.0 */
/**
 * @file buttons_irq.c
 * @brief Minimal latched-button ISR; platform code owns interrupt-controller setup.
 *
 * License details: LICENSE.md at repository root.
 */
#include "gbesp32_examples.h"

/** Handler only. Platform uses XIntc generated ID/parent and enables CPU IRQ.
 * Read source then W1C it before controller acknowledgement. Never print here.
 * A further change during acknowledge leaves the level asserted for re-entry. */
void GBEsp32_ButtonHandler(void *Reference)
{
    GBEsp32_ButtonContext *C = (GBEsp32_ButtonContext *)Reference;
    if (C != 0 && C->Device != 0 && GBEsp32_IrqPending(C->Device)) {
        C->Buttons = GBEsp32_Buttons(C->Device);
        ++C->Events;
        (void)GBEsp32_IrqAcknowledge(C->Device);
    }
}
