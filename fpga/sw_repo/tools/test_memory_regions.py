"""Synthetic HWH unit tests; not a native Vitis/XSA hardware qualification."""
import tempfile
from pathlib import Path
import unittest
import zipfile
from gamebub_memory_regions import from_xsa, add_to_app


class Regions(unittest.TestCase):
    def fixture(self, entries):
        modules = '<MODULE INSTANCE="cpu_renamed" MODTYPE="microblaze_riscv"><MEMORYMAP>'
        for instance, ip, base, size, block in entries:
            for bus in ("DATA", "INSTRUCTION"):
                modules += f'<MEMRANGE INSTANCE="{instance}" BASEVALUE="{hex(base)}" HIGHVALUE="{hex(base+size-1)}" ADDRESSBLOCK="{block}" MEMTYPE="MEMORY" IS_DATA="TRUE" BUSNAME="{bus}"/>'
        modules += '</MEMORYMAP></MODULE>'
        modules += ''.join(f'<MODULE INSTANCE="{name}" MODTYPE="{ip}"/>' for name, ip, *_ in entries)
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        path = Path(tmp.name) / "test.xsa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("top.hwh", "<SYSTEM><MODULES>"+modules+"</MODULES></SYSTEM>")
        return from_xsa(path, "cpu_renamed")

    def test_single_sram(self):
        rows = self.fixture([("ram_any_name", "gamebub_sram_mem", 0x76000000, 524288, "Mem")])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["name"], "gbmem_ram_any_name")

    def test_single_sdram(self):
        self.assertEqual(self.fixture([("dram", "gamebub_sdram_mem", 0x80000000, 33554432, "Mem")])[0]["size"], 33554432)

    def test_both_multiple_and_no_csr(self):
        rows = self.fixture([("s0", "gamebub_sram_mem", 0x76000000, 524288, "Mem"), ("s1", "gamebub_sram_mem", 0x76100000, 524288, "Mem"), ("d", "gamebub_sdram_mem", 0x80000000, 33554432, "Mem"), ("csrs", "gamebub_sdram_mem", 0x44000000, 8192, "Reg")])
        self.assertEqual(len(rows), 3)

    def test_bad_length(self):
        with self.assertRaises(ValueError):
            self.fixture([("ram", "gamebub_sram_mem", 0x76000000, 65536, "Mem")])

    def test_overlap(self):
        with self.assertRaises(ValueError):
            self.fixture([("ram", "gamebub_sram_mem", 0x80000000, 524288, "Mem"), ("dram", "gamebub_sdram_mem", 0x80000000, 33554432, "Mem")])

    def test_empty(self):
        self.assertEqual(self.fixture([]), [])

    def test_linker_preflight(self):
        class Linker:
            rows = [{"name": "already_native", "base_address": "0x76000000", "size": "0x80000"}]
            def get_memory_regions(self): return self.rows
            def add_memory_region(self, **row): self.rows.append(row)
        class App:
            linker = Linker()
            def get_ld_script(self): return self.linker
        app = App()
        regions = self.fixture([("ram", "gamebub_sram_mem", 0x76000000, 524288, "Mem")])
        add_to_app(app, regions)
        self.assertEqual(len(app.linker.rows), 1)
        regions[0]["base"] += 4
        with self.assertRaises(ValueError): add_to_app(app, regions)
        self.assertEqual(len(app.linker.rows), 1)


if __name__ == "__main__":
    unittest.main()
