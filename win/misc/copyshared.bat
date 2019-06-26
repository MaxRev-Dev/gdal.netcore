@echo off
set rx=%_buildroot_%\shared
if not exist "%rx%\bin" mkdir "%rx%\bin"
if not exist "%rx%\lib" mkdir "%rx%\lib"
if "%~x1" == ".dll" (xcopy   /Y /R /F "%1" "%rx%\bin\")
if "%~x1" == ".lib" (xcopy   /Y /R /F "%1" "%rx%\lib\")
