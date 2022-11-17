@echo off
call configvars
set sources=%features%
goto init

:init
set _end=
for %%s in (%sources%) do (
call :yellow  "Removing old builds of %%s"
if exist "%_buildroot_%/%%s-build" rd /q /s "%_buildroot_%/%%s-build")
goto rmsources

:main
for %%s in (%sources%) do (
call :green  "Fetching sources and building - %%s"
call get%%s
call :green  "Finished building task- %%s")
set _end=true

:rmsources
for %%s in (%sources%) do (
if defined _rmsource_ (
	call :yellow  "Removing sources  of %%s"
	if exist "%_buildroot_%/%%s-source" rd /q /s "%_buildroot_%/%%s-source")
)
if  defined _end goto end
goto main
:end
set _end=


:green
powershell -Command Write-Host "%*" -foreground "green" -background "black"
goto :EOF

:yellow
powershell -Command Write-Host "%*" -foreground "yellow" -background "black"
