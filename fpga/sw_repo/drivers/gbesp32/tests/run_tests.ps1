$ErrorActionPreference='Stop'
$driver=Split-Path $PSScriptRoot -Parent
$testOutput=Join-Path ([IO.Path]::GetTempPath()) ('gbesp32-tests-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $testOutput | Out-Null
$env:PATH='C:/msys64/ucrt64/bin;'+$env:PATH
& C:/msys64/ucrt64/bin/gcc.exe -std=c11 -Wall -Wextra -Werror -I "$PSScriptRoot/include" -I "$driver/src" "$driver/src/gbesp32.c" "$driver/src/gbesp32_sinit.c" "$PSScriptRoot/test_gbesp32.c" -o "$testOutput/test.exe"
if($LASTEXITCODE -ne 0) { throw 'driver compile failed' }
& "$testOutput/test.exe"
if($LASTEXITCODE -ne 0) { throw 'mock MMIO test failed' }
