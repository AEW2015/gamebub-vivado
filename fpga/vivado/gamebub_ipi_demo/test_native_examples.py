"""Vitis2025.2 backend Import Examples verification in an explicitly owned workspace.

This intentionally exercises the installed backend ImportExample request, not a
manual source-copy approximation. It is an optional internal-API test, not a
supported public Vitis API promise. Default is metadata inspection; --execute
creates four fresh native_* components, builds them, and never runs hardware.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys

CHOICES = {'gbesp32':'esp32_poll.c', 'gbaudio':'audio_safety.c',
           'gbsram':'gbsram_probe_example.c', 'gbsdram':'gbsdram_probe_example.c'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('workspace',type=Path)
    parser.add_argument('--platform',default='gamebub_platform')
    parser.add_argument('--domain',default='standalone_cpu')
    parser.add_argument('--execute',action='store_true')
    parser.add_argument('--confirm-owned-workspace',action='store_true',required=True)
    parser.add_argument('--output',type=Path)
    ns=parser.parse_args()
    workspace=ns.workspace.resolve()
    if not workspace.is_dir():
        raise RuntimeError('An existing owned SDK workspace is required')
    if not ns.confirm_owned_workspace:
        raise RuntimeError('Explicit owned-workspace confirmation is required')
    install=Path(os.environ.get('XILINX_VITIS','')).resolve()
    if '2025.2' not in install.as_posix() or not (install/'cli/vitis/component.py').is_file():
        raise RuntimeError('UNSUPPORTED: requires the inspected installed Vitis2025.2')
    output=(ns.output or workspace/'native-example-evidence').resolve()
    output.mkdir(parents=True,exist_ok=False)
    import vitis
    import bsp_pb2
    import components_pb2
    from google.protobuf.json_format import MessageToDict
    from vitis import component, _utils
    fields=components_pb2.CreateComponentRequest.DESCRIPTOR.fields_by_name
    if 'import_example' not in fields or set(components_pb2.ImportExample.DESCRIPTOR.fields_by_name)!={'example_name','instance_library_name'}:
        raise RuntimeError('UNSUPPORTED: installed ImportExample schema changed')
    evidence={'status':'INCOMPLETE','workspace':str(workspace),'hardware_access':'none',
              'mechanism':'installed2025.2 backend CreateComponentRequest.import_example',
              'api_stability':'internal and version guarded; not public API guarantee',
              'executed':ns.execute,'apps':[],
              'source_bindings':{str(p):digest(p) for p in [Path(__file__).resolve(),
                  install/'cli/vitis/component.py',install/'cli/proto/components_pb2.py',
                  install/'cli/proto/bsp_pb2.py',install/'data/embeddedsw/scripts/pyesw/create_example.py']}}
    client=vitis.create_client()
    try:
        client.set_workspace(str(workspace))
        platform=client.get_component(name=ns.platform)
        domain=platform.get_domain(ns.domain)
        request=bsp_pb2.BSPDataRequest(platform_location=domain.platform_location,
                                      domain_name=domain.domain_name,id=_utils.generate_unique_uuid())
        metadata=domain.stub.GetBSPData(request)
        data=MessageToDict(metadata,preserving_proto_field_name=True)
        (output/'bsp-data.json').write_text(json.dumps(data,indent=2)+'\n')
        available={}
        for driver in metadata.bsp_driver:
            if driver.name not in CHOICES:
                continue
            # ip_instance is the native drv_info key, not the generic driver name.
            # create_example.py resolves that instance key to its path/examples.
            examples={entry.example_name:list(entry.sources) for entry in driver.examples}
            item={'driver':driver.name,'ip_instance':driver.ip_instance,
                  'ip_type':driver.ip_type,'path':driver.value,'examples':examples}
            available[driver.name]=item
        evidence['discovery']=available
        (output/'discovered-examples.json').write_text(json.dumps(available,indent=2)+'\n')
        for name,example in CHOICES.items():
            matches=[] if name not in available else [key for key,sources in available[name]['examples'].items() if example in sources]
            if len(matches)!=1 or not available[name]['ip_instance']:
                raise RuntimeError('UNSUPPORTED: native BSP does not advertise expected example: '+name+'/'+example)
            available[name]['selected_example']=matches[0]
            # BSPData presents a display stem, but native create_example.py
            # indexes bsp.yaml examples by the source filename including .c.
            # The filename comes from the backend's sources list, not a guessed ID.
            available[name]['selected_source']=example
            driver_path=Path(available[name]['path'])
            for source in [driver_path/'examples'/example,driver_path/'data'/(name+'.yaml')]:
                evidence['source_bindings'][str(source)]=digest(source)
        print('NATIVE_EXAMPLE_DISCOVERY_PASS drivers=4',flush=True)
        if not ns.execute:
            evidence['status']='DISCOVERY_PASS'
            return
        xpfm=client.find_platform_in_repos(ns.platform)
        stub=component.Component(client._serverObj)._stub
        for driver,example in CHOICES.items():
            name='native_'+driver+'_example'
            location=workspace/name
            if location.exists():
                raise RuntimeError('Refusing to overwrite existing component: '+str(location))
            req=components_pb2.CreateComponentRequest(component_name=name,component_location=str(location),
                component_type=components_pb2.Component.Type.HOST,platform=xpfm,domain=ns.domain,
                import_example=components_pb2.ImportExample(example_name=available[driver]['selected_source'],
                    instance_library_name=available[driver]['ip_instance']))
            (output/(name+'.request.json')).write_text(json.dumps(MessageToDict(req,preserving_proto_field_name=True),indent=2)+'\n')
            created=stub.CreateComponent(req)
            app=client.get_component(name=name)
            if app.component_location!=created.component_location:
                raise RuntimeError('Created component did not resolve through public get_component')
            result=app.build()
            elfs=list((location/'build').glob('*.elf'))
            item={'driver':driver,'example':example,'component':name,'build_return':result,
                  'elfs':[{'path':str(p.relative_to(workspace)),'sha256':digest(p)} for p in elfs]}
            evidence['apps'].append(item)
            if result!=0 or len(elfs)!=1:
                raise RuntimeError('Native imported example build failed: '+name)
            print('NATIVE_EXAMPLE_IMPORT_BUILD_PASS '+driver+'/'+example,flush=True)
        evidence['status']='PASS'
    except Exception as exc:
        evidence['status']='UNSUPPORTED_OR_FAILED'
        evidence['error']=str(exc)
        raise
    finally:
        (output/'result.json').write_text(json.dumps(evidence,indent=2)+'\n')
        vitis.dispose()


if __name__=='__main__':
    main()
