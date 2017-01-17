@echo off

SETLOCAL 
SET outdir=bin
SET outfile=fighter

RMDIR /S /Q %outdir%
mkdir %outdir%

nim --out:%outdir%\%outfile% --nimcache:nimcache c src\main.nim 

REM ====== LIBRARY COPIES
copy /Y lib\SDL2_image.dll %outdir%\ >nul
copy /Y lib\libjpeg-9.dll %outdir%\ >nul

REM ====== ASSETS
xcopy res %outdir%\res /S /I >nul