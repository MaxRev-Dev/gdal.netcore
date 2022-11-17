@echo off
for /F %%I in ('dir /s/b "%1\*.dll"') do (
call %__%\copyshared "%%I"
@echo off
)

for /F %%I in ('dir /s/b "%1\*.lib"') do (
@echo on
call %__%\copyshared "%%I"
@echo off
)