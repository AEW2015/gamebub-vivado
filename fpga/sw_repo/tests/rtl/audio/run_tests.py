"""Exact packaged audio 1.3 nominal-clock AXI/watchdog regression, no tick forcing."""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path
import subprocess
import tempfile

REPO=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
IP=REPO/'fpga/ip_repo/gamebub_dac_audio_v1_3'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    args=parser.parse_args()
    output=args.output or Path(tempfile.mkdtemp(prefix='gb-audio-exact-rtl-'))
    if args.output:
        output.mkdir(parents=True,exist_ok=False)
    env=dict(os.environ)
    iverilog=shutil.which('iverilog') or 'C:/msys64/ucrt64/bin/iverilog.exe'
    vvp=shutil.which('vvp') or 'C:/msys64/ucrt64/bin/vvp.exe'
    env['PATH']=str(Path(iverilog).parent)+os.pathsep+env.get('PATH','')
    sources=[HERE/'oddr_stub.v',HERE/'tb_contract.sv',IP/'hdl/gamebub_dac_audio.v',
             IP/'src/speaker_peripheral.sv',IP/'src/speaker_engine.sv']
    binary=output/'contract.vvp'
    cmd=[iverilog,'-g2012','-s','tb_contract','-I',str(IP/'src'),
         '-o',str(binary),*map(str,sources)]
    compiled=subprocess.run(cmd,env=env,capture_output=True,text=True,timeout=60)
    (output/'compile.log').write_text(compiled.stdout+compiled.stderr)
    if compiled.returncode:
        raise RuntimeError(compiled.stderr)
    print('AUDIO_RTL_RUN nominal_clock=29361979 timeout_seconds=600',flush=True)
    result=subprocess.run([vvp,str(binary)],env=env,
                          capture_output=True,text=True,timeout=600)
    log=result.stdout+result.stderr
    (output/'run.log').write_text(log)
    print(log,end='',flush=True)
    if result.returncode or 'AUDIO_EXACT_RTL_PASS' not in log:
        raise RuntimeError('Audio RTL contract assertion failed')
    sources.append(IP/'src/tone_sine.vh')
    manifest={'status':'PASS','dut':'gamebub.org:ip:gamebub_dac_audio:1.3',
              'tool':'Icarus Verilog','compile_command':cmd,'returncode':result.returncode,
              'parameters':'Packaged defaults unchanged; nominal clock; no accelerated/forced timer',
              'limits':['Functional ODDR model only; no physical timing','No acoustic output measurement',
                        'Watchdog/AXI contract, not comprehensive waveform/DAC endpoint simulation'],
              'sources':[{'path':str(p.relative_to(REPO)).replace('\\','/'),
                          'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]}
    (output/'result.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('AUDIO_RTL_EVIDENCE='+str(output))

if __name__=='__main__':
    main()
