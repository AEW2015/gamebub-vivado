"""Execute exact current v1.6 CSR/backend RTL tests; no PHY/hardware claim."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
CASES = {
    "tb_sram_regs": ["fpga/ip_repo/gamebub_sram_mem_v1_6/src/sram_shared_test_regs.sv"],
    "tb_sdram_control": ["fpga/ip_repo/gamebub_sdram_mem_v1_6/src/s4_shared_axi.sv", "fpga/ip_repo/gamebub_sdram_mem_v1_6/src/s4_shared_backend.sv"],
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    out = args.output or Path(tempfile.mkdtemp(prefix="gb-memory-rtl-"))
    if args.output:
        out.mkdir(parents=True, exist_ok=False)
    exe = shutil.which("iverilog") or "C:/msys64/ucrt64/bin/iverilog.exe"
    vvp = shutil.which("vvp") or "C:/msys64/ucrt64/bin/vvp.exe"
    env = os.environ.copy()
    env["PATH"] = str(Path(exe).parent)+os.pathsep+env.get("PATH", "")
    results = []
    for top, names in CASES.items():
        sources = [HERE/(top+".sv")] + [REPO/name for name in names]
        compile_cmd = [exe, "-g2012", "-s", top, "-o", str(out/(top+".vvp"))] + [str(s) for s in sources]
        logs = []
        result = subprocess.run(compile_cmd, env=env, capture_output=True, text=True, timeout=60)
        logs.append(result.stdout+result.stderr)
        if result.returncode == 0:
            result = subprocess.run([vvp, str(out/(top+".vvp"))], env=env, capture_output=True, text=True, timeout=60)
            logs.append(result.stdout+result.stderr)
        (out/(top+".log")).write_text("\n".join(logs), encoding="utf-8")
        good = result.returncode == 0 and "_PASS" in result.stdout
        results.append({"top":top,"status":"PASS" if good else "FAIL", "sources":[{"path":str(s),"sha256":hashlib.sha256(s.read_bytes()).hexdigest()} for s in sources]})
        print(top, results[-1]["status"], "\n".join(logs))
    (out/"results.json").write_text(json.dumps(results, indent=2)+"\n", encoding="utf-8")
    print("Evidence",out)
    return 0 if all(row["status"] == "PASS" for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
