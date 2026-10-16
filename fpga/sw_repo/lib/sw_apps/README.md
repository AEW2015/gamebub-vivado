# GameBub native embedded application templates

Add the **software repository root** (`fpga/sw_repo`) through Vitis 2025.2's **Embedded SW Repositories...**, not this `sw_apps` subdirectory. Then use **Examples > Embedded Software Examples** and select a **GameBub -** template. See the [sidebar walkthrough](../../../../docs/vivado/vitis-examples.md).

The generated template directories are committed so ordinary users need no generator. Each contains `data/<template>.yaml` and self-contained `src` files. Vitis supplies the selected platform's metadata, linker support and UserConfig during creation.

For development, edit the canonical [template inputs](../../templates/apps.json), shared application source or driver examples, then run:

```powershell
python fpga/sw_repo/tools/generate_app_templates.py
python fpga/sw_repo/tools/generate_app_templates.py --check
```

Do not maintain divergent hand-edited copies in the generated template directories. Customize the imported application's `gamebub_settings.h` only after reading the memory/actuator safety rules; defaults keep destructive operations disabled.
