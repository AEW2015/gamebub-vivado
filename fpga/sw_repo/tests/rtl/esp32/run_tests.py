"""Execute unchanged packaged ESP32 1.14 RTL with pin-only primitive models."""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
IP = REPO / 'fpga/ip_repo/gamebub_esp32_v102_v1_14/src'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    output = args.output or Path(tempfile.mkdtemp(prefix='gb-esp32-exact-rtl-'))
    if args.output:
        output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ)
    iverilog = shutil.which('iverilog') or 'C:/msys64/ucrt64/bin/iverilog.exe'
    vvp = shutil.which('vvp') or 'C:/msys64/ucrt64/bin/vvp.exe'
    env['PATH'] = str(Path(iverilog).parent) + os.pathsep + env.get('PATH', '')
    sources = [HERE/'primitive_stubs.v', HERE/'tb_contract.sv', IP/'gamebub_esp32_v102.v',
               IP/'esp32_v102_endpoint.sv', IP/'esp32_overlay_axis.sv']
    cases = []
    for enabled in (0, 1):
        binary = output / f'overlay{enabled}.vvp'
        cmd = [iverilog, '-g2012', '-s', 'tb_contract']
        if enabled:
            cmd.append('-DOVERLAY')
        cmd += ['-o', str(binary), *map(str, sources)]
        compile_result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=60)
        (output/f'overlay{enabled}.compile.log').write_text(compile_result.stdout+compile_result.stderr)
        if compile_result.returncode:
            raise RuntimeError('RTL compile failed: '+compile_result.stderr)
        result = subprocess.run([vvp, str(binary)], env=env,
                                capture_output=True, text=True, timeout=60)
        log = result.stdout + result.stderr
        (output/f'overlay{enabled}.run.log').write_text(log)
        print(log, end='', flush=True)
        if result.returncode or f'ESP32_EXACT_RTL_PASS overlay={enabled}' not in log:
            raise RuntimeError('RTL contract assertion failed')
        cases.append({'overlay': enabled, 'status':'PASS', 'compile_command':cmd,
                      'returncode':result.returncode})
    manifest = {'status':'PASS', 'tool':'Icarus Verilog', 'cases':cases,
                'dut':'gamebub.org:ip:gamebub_esp32_v102:1.14',
                'limits':['Functional OBUF/IOBUF pin models only; no physical timing or metastability',
                          'CPU overlay storage checks, not complete stream/display verification',
                          'QSPI pins idle; this test checks CPU contract, not serial protocol'],
                'sources':[{'path':str(p.relative_to(REPO)).replace('\\','/'),
                            'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]}
    (output/'result.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('ESP32_RTL_EVIDENCE='+str(output))

if __name__ == '__main__':
    main()
