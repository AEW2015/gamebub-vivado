$ErrorActionPreference='Stop'
$driver=Split-Path $PSScriptRoot -Parent
$mock=Join-Path $driver '../gbesp32/tests/include'
$testOutput=Join-Path ([IO.Path]::GetTempPath()) ('gbaudio-tests-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $testOutput | Out-Null
$env:PATH='C:/msys64/ucrt64/bin;'+$env:PATH
& C:/msys64/ucrt64/bin/gcc.exe -std=c11 -Wall -Wextra -Werror -I "$mock" -I "$driver/src" "$driver/src/gbaudio.c" "$driver/src/gbaudio_sinit.c" "$PSScriptRoot/test_gbaudio.c" -o "$testOutput/test.exe"
if($LASTEXITCODE -ne 0) { throw 'driver compile failed' }
& "$testOutput/test.exe"
if($LASTEXITCODE -ne 0) { throw 'mock MMIO test failed' }
