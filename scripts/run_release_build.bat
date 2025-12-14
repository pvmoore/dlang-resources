@echo off
chcp 65001
dub run --build=release --config=%1% --compiler=ldc2 --arch=x86_64 --parallel