include RID.opt
include ../shared/GdalCore.opt

all:
#	install libraries with VCPKG
	@$(MAKE) -f vcpkg-makefile || exit 1

#	install main libraries (proj,gdal)
	@$(MAKE) -f gdal-makefile || exit 1

#	collect dynamic libraries
	@$(MAKE) -f collect-deps-makefile || exit 1

#	create packages (output to 'nuget' folder)
	@$(MAKE) -f publish-makefile pack || exit 1

#	testing packages
#	optional PRERELEASE=1 - testing pre-release versions
#	optional APP_RUN=1 - testing via console app run (quick, to ensure deps were loaded correctly)
	@$(MAKE) -f test-makefile test || exit 1