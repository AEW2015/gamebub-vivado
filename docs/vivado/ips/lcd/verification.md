# LCD verification

The canonical RTL is packaged under `fpga/ip_repo/gamebub_lcd_axis_v1_5`. Reuse existing video/overlay tests but bind their source list to this exact directory, not a same-name historical copy.

Required cases cover SOF/EOL alignment, input/output backpressure, transparent/opaque overlay selection, reset mid-frame, missing pixels, malformed framing, reacquisition and RGB byte packing. The compositor cannot pause the panel; include an underflow case that observes blacking and the next frame, not just ready/valid handshakes.

The reference reconstruction/XSA check establishes IPI wiring only. Driver host tests do not simulate a panel. Hardware acceptance requires a timing-qualified matching bitstream and physical checks of bars, all edges, orientation, and a real ESP32 volume overlay that clears back to video. Historical observations from another image must not be recorded as a fresh PASS.

See the [validation ledger](../../validation.md) for the executed gates and outstanding work.
