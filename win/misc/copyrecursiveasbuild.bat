if not exist "%2-build" mkdir "%2-build"
@echo off
set _lroot_=%__%\copysharednamed
if not "%3" == "" (
for /F %%I in ('dir /s/b "%1\%3.exe"') do (
@echo on
call %_lroot_% "%_buildroot_%/%2-build/bin" "%%I"
@echo off
))
for /F %%I in ('dir /s/b "%1\*.dll"') do (
@echo on
call %_lroot_% "%_buildroot_%/%2-build/bin" "%%I"
@echo off
)

for /F %%I in ('dir /s/b "%1\*.h"') do (
@echo on
call %_lroot_% "%_buildroot_%/%2-build/include" "%%I"
@echo off
)

for /F %%I in ('dir /s/b "%1\*.lib"') do (
@echo on
call %_lroot_% "%_buildroot_%/%2-build/lib" "%%I"
@echo off
)
