@echo off

pushd .

cd bzip3

set FILES=src\libbz3.c 

set HEADERS=-Iinclude

cl %HEADERS% %FILES% /nologo /utf-8 /arch:AVX2 /TC /std:c11 /O2 /c

rem package obj files into bzip3.lib
IF %ERRORLEVEL% EQU 0 (
    lib *.obj /nologo /out:..\..\..\bzip3.lib
    del *.obj
)

popd
