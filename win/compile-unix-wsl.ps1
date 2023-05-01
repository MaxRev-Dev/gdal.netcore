# Prerequisites: WSL2, Debian
# Repository must be cloned in WSL2 Debian into /root/gdal.netcore

wsl -d Debian --cd /root/gdal.netcore/unix -- make 

# copy nuget from wsl to ./nuget folder
Copy-Item -Path '//wsl$/Debian/root/gdal.netcore/nuget/*.nupkg' -Destination "$PSScriptRoot/../nuget"