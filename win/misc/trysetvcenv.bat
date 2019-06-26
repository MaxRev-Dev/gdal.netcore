@echo off
call %~dp0..\configvars.bat
if not defined WindowsSdkDir (call %_vcvars_%)