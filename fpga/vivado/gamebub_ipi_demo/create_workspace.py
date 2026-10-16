"""Vitis 2025.2: native driver discovery and separate apps, no hardware access."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile
import vitis

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
APPS=['hello_jtag','esp32_poll','qspi_diagnostics','cpu_overlay','tpg_bars',
      'tpg_patterns','audio_tone','vibration_pulse','sram_probe','sdram_probe',
      'buttons_irq','custom_demo','sram_scratch','sdram_scratch']
DRIVER_APPS={
    'sram_instruction':('gbsram','gbsram_instruction_example.c'),
    'sram_test':('gbsram','gbsram_test_example.c'),
    'sdram_instruction':('gbsdram','gbsdram_instruction_example.c'),
    'sdram_test':('gbsdram','gbsdram_test_example.c'),
    'sdram_timing':('gbsdram','gbsdram_timing_example.c'),
}


def hardware(xsa):
    with zipfile.ZipFile(xsa) as archive:
        roots=[ET.fromstring(archive.read(n)) for n in archive.namelist() if n.endswith('.hwh')]
    roots=[r for r in roots if any(m.get('MODTYPE')=='microblaze_riscv' for m in r.iter('MODULE'))]
    if len(roots)!=1: raise ValueError('Need one MicroBlaze V hardware handoff')
    mods={m.get('INSTANCE'):m for m in roots[0].iter('MODULE')}
    cpus=[m for m in mods.values() if m.get('MODTYPE')=='microblaze_riscv']
    if len(cpus)!=1: raise ValueError('Select one-processor reference')
    cpu=cpus[0];bindings={};ranges=[]
    keys={'gamebub_esp32_v102':'ESP32','gamebub_dac_audio':'AUDIO','axi_gpio':'VIBRATION',
          'axi_intc':'INTC','v_tpg':'TPG','gamebub_sram_mem':'SRAM','gamebub_sdram_mem':'SDRAM'}
    for span in cpu.iter('MEMRANGE'):
        if span.get('IS_DATA')!='TRUE': continue
        kind=mods[span.get('INSTANCE')].get('MODTYPE')
        base=int(span.get('BASEVALUE'),0);size=int(span.get('HIGHVALUE'),0)-base+1
        if span.get('MEMTYPE')=='MEMORY' and kind=='lmb_bram_if_cntlr': bindings['BRAM_SIZE']=size
        if kind not in keys: continue
        key=keys[kind]
        suffix='MEMORY_BASE' if span.get('MEMTYPE')=='MEMORY' else ('CTRL_BASE' if key in {'SRAM','SDRAM'} else 'BASE')
        bindings[f'{key}_{suffix}']=base
        if suffix=='MEMORY_BASE':
            bindings[f'{key}_MEMORY_SIZE']=size
            ranges.append({'name':'gamebub_'+key.lower(),'base':base,'size':size})
    params={p.get('NAME'):p.get('VALUE') for p in cpu.iter('PARAMETER')}
    bindings['CPU_HZ']=int(params['C_FREQ'],0)
    if bindings['BRAM_SIZE']!=16384: raise ValueError('Reference BRAM size changed; review ELF bounds')
    for key in ('ESP32_BASE','AUDIO_BASE','VIBRATION_BASE','INTC_BASE','TPG_BASE','SRAM_CTRL_BASE','SDRAM_CTRL_BASE','SRAM_MEMORY_BASE','SDRAM_MEMORY_BASE'):
        if key not in bindings: raise ValueError('Missing reference endpoint '+key)
    return cpu.get('INSTANCE'), bindings, ranges


def elf_bounds(path, limit):
    data=path.read_bytes()
    if data[:6]!=b'\x7fELF\x01\x01': raise ValueError('Need little-endian RV32 ELF')
    if struct.unpack_from('<H',data,18)[0]!=243: raise ValueError('ELF is not RISC-V')
    entry,offset=struct.unpack_from('<II',data,24)
    entsize,count=struct.unpack_from('<HH',data,42)
    loads=[]
    for index in range(count):
        kind,_,_,physical,_,size,_,_=struct.unpack_from('<IIIIIIII',data,offset+index*entsize)
        if kind==1 and size:
            if physical+size>limit: raise ValueError('ELF loads outside boot BRAM')
            loads.append({'address':physical,'bytes':size})
    if entry>=limit or not loads: raise ValueError('Invalid boot entry')
    return {'entry':entry,'loads':loads}


def main():
    args=argparse.ArgumentParser(description=__doc__)
    args.add_argument('xsa',type=Path);args.add_argument('workspace',type=Path)
    args.add_argument('--apps',default=','.join(APPS+list(DRIVER_APPS)))
    args.add_argument('--app',action='append',help='Select one app; repeat this option to avoid Windows batch comma splitting')
    args.add_argument('--allow-destructive',action='store_true',help='Enable scratch writes; application still needs isolated hardware')
    args.add_argument('--confirm-isolated-memory',action='store_true',help='Confirm reserved range, all clients parked and BRAM execution requirements')
    args.add_argument('--scratch-offset',type=lambda x:int(x,0))
    args.add_argument('--scratch-bytes',type=lambda x:int(x,0))
    args.add_argument('--allow-retiming',action='store_true')
    ns=args.parse_args();xsa=ns.xsa.resolve();work=ns.workspace.resolve()
    if work.exists(): raise ValueError('Fresh workspace directory required')
    chosen=ns.app or ns.apps.split(',')
    if not chosen or any(name not in APPS and name not in DRIVER_APPS for name in chosen): raise ValueError('Unknown application')
    if ns.allow_destructive and (not ns.confirm_isolated_memory or ns.scratch_offset is None or ns.scratch_bytes is None):
        raise ValueError('Destructive build requires explicit isolated-memory confirmation and scratch offset/bytes')
    if ns.allow_retiming and not ns.allow_destructive: raise ValueError('Retiming requires destructive/BRAM safety confirmation')
    cpu,bindings,regions=hardware(xsa)
    sys.path.insert(0,str(ROOT/'fpga/sw_repo/tools'))
    from gamebub_memory_regions import from_xsa,add_to_app
    regions=from_xsa(xsa,cpu)
    client=vitis.create_client()
    try:
        client.set_workspace(str(work))
        client.add_embedded_sw_repo(level='LOCAL',path=str(ROOT/'fpga/sw_repo'))
        platform=client.create_platform_component(name='gamebub_platform',hw_design=str(xsa),cpu=cpu,os='standalone',domain_name='standalone_cpu',generate_dtb=False)
        domain=platform.get_domain('standalone_cpu')
        domain.set_config('os','standalone_stdout','mdm_1');domain.set_config('os','standalone_stdin','mdm_1')
        if platform.build()!=0: raise RuntimeError('Platform build failed')
        drivers=domain.get_drivers()
        (work/'native-driver-list.json').write_text(json.dumps(drivers,indent=2,default=str)+'\n')
        for expected in ('gbesp32','gbsram','gbsdram','gbaudio'):
            if expected not in str(drivers): raise RuntimeError('Native BSP driver not discovered: '+expected)
        print('SDK_NATIVE_DRIVER_DISCOVERY_PASS',flush=True)
        # Verify IRQ metadata from actual generated SDT, not a guessed vector.
        texts='\n'.join(p.read_text(errors='replace') for p in work.rglob('pl.dtsi'))
        irq=re.search(r'gamebub_esp32_v102@[^}]+?interrupts\s*=\s*<\s*(\d+)\s+(\d+)\s*>',texts,re.S)
        if not irq or int(irq.group(2))!=2: raise ValueError('Expected actual level-high ESP32 SDT interrupt')
        bindings['ESP32_IRQ']=int(irq.group(1))
        evidence={'xsa_sha256':hashlib.sha256(xsa.read_bytes()).hexdigest(),'cpu':cpu,'bindings':bindings,
                  'driver_discovery':'native SDT/YAML','linker_registration':'XSA-derived application helper, not native RAM discovery',
                  'hardware_access':'none','destructive_enabled':ns.allow_destructive,'apps':[],
                  'source_bindings':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest()
                    for folder in [ROOT/'fpga/sw_repo',HERE] for p in folder.rglob('*')
                    if p.is_file() and '__pycache__' not in p.parts and p.suffix in {'.c','.h','.py','.yaml','.tcl','.json'}}}
        for name in chosen:
            source=work/'generated_sources'/name;source.mkdir(parents=True)
            (source/'platform_bindings.h').write_text('\n'.join(f'#define GB_{k} 0x{v:X}U' for k,v in bindings.items())+'\n')
            defines=f'#define GB_ALLOW_DESTRUCTIVE {int(ns.allow_destructive)}\n#define GB_BRAM_EXECUTION_CONFIRMED {int(ns.confirm_isolated_memory)}\n#define GB_SCRATCH_OFFSET {ns.scratch_offset or 0}\n#define GB_SCRATCH_BYTES {ns.scratch_bytes or 0}\n'
            if name in DRIVER_APPS:
                driver,example=DRIVER_APPS[name]
                key='SRAM' if driver=='gbsram' else 'SDRAM'
                text='#include "platform_bindings.h"\n'+defines+f'#define GB_EXAMPLE_CTRL_BASE GB_{key}_CTRL_BASE\n#define GB_EXAMPLE_MEMORY_BASE GB_{key}_MEMORY_BASE\n#define GB_ALLOW_RETIMING {int(ns.allow_retiming)}\n#include "driver_example.inc"\n'
                # Vitis compiles every imported .c separately. Include the
                # example as .inc so there is exactly one main translation unit.
                (source/'driver_example.inc').write_bytes((ROOT/'fpga/sw_repo/drivers'/driver/'examples'/example).read_bytes())
            else:
                text=defines+f'#define GB_APP_NAME "{name}"\n#define GB_DEMO_KIND {APPS.index(name)+1}\n#include "demo_program.h"\n'
            (source/'main.c').write_text(text)
            app=client.create_app_component(name=name,platform=client.find_platform_in_repos('gamebub_platform'),domain='standalone_cpu',template='empty_application')
            linker=add_to_app(app,regions);linker.set_stack_size('0x800');linker.set_heap_size('0x0')
            app.import_files(from_loc=str(source),files=['main.c','platform_bindings.h'])
            if name in DRIVER_APPS:
                driver,example=DRIVER_APPS[name]
                app.import_files(from_loc=str(source),files=['driver_example.inc'])
                app.import_files(from_loc=str(ROOT/'fpga/sw_repo/drivers'/driver/'examples'),files=[driver+'_example_setup.h'])
            else:
                app.import_files(from_loc=str(HERE/'software'),files=['demo_program.h'])
            if app.build()!=0: raise RuntimeError('Application build failed: '+name)
            elfs=list((work/name/'build').glob('*.elf'))
            if len(elfs)!=1: raise RuntimeError('Expected one ELF for '+name)
            detail=elf_bounds(elfs[0],bindings['BRAM_SIZE'])
            detail.update(name=name,elf=str(elfs[0].relative_to(work)),sha256=hashlib.sha256(elfs[0].read_bytes()).hexdigest())
            evidence['apps'].append(detail)
            print('SDK_APP_BUILD_PASS '+name,flush=True)
        evidence['overall']='PASS'
        (work/'build-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
    finally:
        vitis.dispose()


if __name__=='__main__': main()
