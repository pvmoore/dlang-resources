@echo off

pushd .

cd bzip2

set FILES=bzlib.c blocksort.c crctable.c huffman.c randtable.c compress.c decompress.c

cl %FILES% /nologo /utf-8 /arch:AVX2 /TC /std:c11 /O2 /c

rem package obj files into bzip2.lib
IF %ERRORLEVEL% EQU 0 (
    lib *.obj /nologo /out:..\..\..\bzip2.lib
    del *.obj
)

popd
