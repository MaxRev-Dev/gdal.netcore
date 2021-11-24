include RID.opt
include ../shared/GdalCore.opt
include $(GDAL_ROOT)/GDALmake.opt
include $(GDAL_ROOT)/swig/csharp/csharp.opt

ifeq ($(LIBGDAL_CURRENT),)
LIBGDAL_CURRENT := 27
endif

ifeq ($(RID),)
RID=linux-x64
endif

BUILD_BASE_LIB=$(GDAL_BUILD_)/lib
GDAL_SO_VER_=so.$(LIBGDAL_CURRENT)

# suppress warnings..
_suprf_=-Wno-missing-prototypes -Wno-missing-declarations -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-function

# output helper
define \n


endef

all: prebuild build

LINK = $(LD_SHARED)
LINK_EXTRAFLAGS =
OBJ_EXT = o

ifeq ($(HAVE_LIBTOOL),yes)
LINK = $(LD)
LINK_EXTRAFLAGS = -no-undefined -version-info $(LIBGDAL_CURRENT):$(LIBGDAL_REVISION):$(LIBGDAL_AGE)
OBJ_EXT = lo
endif

OUTPUT = $(ROOTDIR_)/runtimes/$(RID)/native
BUILD_BASE =  $(BASE)/bindings

bindings_out = $(BUILD_BASE)

CSHARP_MODULES = libgdalcsharp.$(SO_EXT) libogrcsharp.$(SO_EXT) libgdalconstcsharp.$(SO_EXT) libosrcsharp.$(SO_EXT)
CSHARP_OBJECTS = $(BUILD_BASE)/const/gdalconst_wrap.$(OBJ_EXT) $(BUILD_BASE)/gdal/gdal_wrap.$(OBJ_EXT) $(BUILD_BASE)/osr/osr_wrap.$(OBJ_EXT) $(BUILD_BASE)/ogr/ogr_wrap.$(OBJ_EXT)

$(CSHARP_MODULES): lib%csharp.$(SO_EXT): %_wrap.$(OBJ_EXT)
	$(LINK) $(LDFLAGS) $(CONFIG_LIBS) -Wl,-rpath '-Wl,$$ORIGIN'  $(_suprf_) $< -o $@ $(LINK_EXTRAFLAGS) $(OUTPUT)/libgdal.$(GDAL_SO_VER_)

%.$(OBJ_EXT): %.cpp
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.cxx
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.c
	$(CC) $(CFLAGS) $(GDAL_INCLUDE)  $(_suprf_) -c $<

link_so:
	$(echo ok $< && patchelf --set-rpath '$$ORIGIN' $<)

linkall: clean_runtimes initdirs copygdalout makesolocal copyalldepso copyprojdb
	$(eval _so_out_:=$(wildcard  $(OUTPUT)/*.so*))
	@$(foreach lib, $(_so_out_),  @if [ -a $(lib) ]; then echo "Patching $(lib)" & patchelf --set-rpath '$$ORIGIN' $(lib); fi;${\n})
	@echo "Libraries patched successfully"
	
clean_runtimes:
	rm -rvf $(OUTPUT)/*.* 

echo:
	echo $(CXX)

clean:
	(cd $(BUILD_BASE) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)
	(cd $(PWD) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)

veryclean: clean
	(cd $(BUILD_BASE) && rm -f -R const/*.cs const/*.c gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs ogr/*.cpp Data)
	(cd $(PWD) && rm -f -R *.so *.o ./*.cs gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs *.c *.cpp .libs/ const/ ogr/ osr/ gdal/ obj/ runtimes/ bin/)
	
cleanpackages:
	(cd $(PWD) && rm -f -R $(NUGET_))

interface:
	$(MAKE) -f ./mkinterface

prebuild: interface 

build: ${CSHARP_OBJECTS} ${CSHARP_MODULES} gdal_csharp

install:
	@echo "No installation to be done"

initdirs:
	mkdir -p $(OUTPUT)
	
copygdalout:
	cp -f ${BUILD_BASE_LIB}/libgdal.$(GDAL_SO_VER_) $(OUTPUT)/libgdal.$(GDAL_SO_VER_)

makesolocal:
	$(eval local_o:=$(wildcard *.o))
	$(foreach lib, $(local_o),  g++ -shared -o $(OUTPUT)/$(basename $(lib)).so $(lib) $(OUTPUT)/libgdal.$(GDAL_SO_VER_);${\n})
	
copyalldepso:
	ldd $(BUILD_BASE_LIB)/libgdal.so | grep "=> /" | awk '{print $$3}' | xargs -I {} cp -v {} $(OUTPUT) 
	
copyprojdb:
	-mkdir -p $(LIBSHARED)
	cp -f $(BASE_PROJ)/share/proj/proj.db $(LIBSHARED)

gdal_csharp: linkall  
	@echo "Bindings and drivers are ready to packaging!"

## Creating packages for testing and publishing
# https://github.com/dotnet/core/issues/4404
export MSBUILDSINGLELOADCONTEXT = 1

# make's .EXPORT_ALL_VARIABLES does not work here
# using exprt to add dynamic labraries location
export LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:${VCPKG_INSTALLED_DYNAMIC}/lib

packc:
	dotnet pack -c Release -o $(NUGET_) $(ROOTDIR_)/gdalcore.loader.csproj

packr: 
	dotnet pack -c Release -o $(NUGET_) $(ROOTDIR_)/gdalcore.linuxruntime.csproj

pack: packc packr

packdc: 
	dotnet pack -c Debug -o $(NUGET_) $(ROOTDIR_)/gdalcore.loader.csproj

packdr: 
	dotnet pack -c Debug -o $(NUGET_) $(ROOTDIR_)/gdalcore.linuxruntime.csproj

packdev: packdc packdr
	

###	Testing linux libraries (from nuget build output)
test-update:
	(cd $(TEST_DIR) && dotnet add package MaxRev.Gdal.Core -s $(NUGET_)) 
	(cd $(TEST_DIR) && dotnet add package MaxRev.Gdal.LinuxRuntime.Minimal -s $(NUGET_))
 
test-restore:
	(cd $(TEST_DIR) && dotnet restore -s "https://api.nuget.org/v3/index.json" -s $(NUGET_))

test-only: test-restore
	(cd $(TEST_DIR) && dotnet test)
	
test: test-update test-only
