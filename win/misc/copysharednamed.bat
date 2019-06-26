@echo off
set rx=%~1
if not exist "%rx%" mkdir "%rx%"
xcopy   /Y /R /F "%2" "%rx%/"
