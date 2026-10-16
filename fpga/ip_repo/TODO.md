<!-- SPDX-License-Identifier: 0BSD -->

# IP integration TODOs

- Complete end-to-end/cache/PHY and physical qualification for the public reference; see [validation status](../../docs/vivado/validation.md).
- Prove native SDT external-memory linker discovery rather than relying only on the XSA-derived helper.
- Finish manual GUI example-design/import acceptance and verify new-VLNV driver compatibility before publishing upgraded catalog versions.
- Review every project's related-clock interrupt crossings, packaged CDC exceptions and external-I/O budgets during routed sign-off; do not add blanket false paths.
- Reconcile legacy packaged integration HTML (some refers to board file 1.10) with the canonical [GitHub guides](../../docs/vivado/README.md), which use board file 2.0. Keep functional IP metadata/RTL unchanged until an explicitly versioned package upgrade is qualified.
- Continue ESP32 menu-state/ownership compatibility work separately from successful volume-overlay tests. Do not imply that all installed ESP32 firmware/menu modes are interchangeable.
