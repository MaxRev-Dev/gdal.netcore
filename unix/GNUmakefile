RUNTIME_RID=unix
include ../shared/GdalCore.opt
include $(BASE_GDAL_)/GDALmake.opt
include $(GDAL_ROOT)/swig/csharp/csharp.opt

ifeq ($(LIBGDAL_CURRENT),)
LIBGDAL_CURRENT := 27
endif

ifeq ($(RID),)
RID=linux-x64
endif

GDAL_BASE_LIB=$(GDAL_BUILD_)/lib
GDAL_SO_VER_=so.$(LIBGDAL_CURRENT)

# suppress warnings..
_suprf_=-Wno-missing-prototypes -Wno-missing-declarations -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-function

define \n


endef
all: prebuild

LINK = $(LD_SHARED)
LINK_EXTRAFLAGS =
OBJ_EXT = o

ifeq ($(HAVE_LIBTOOL),yes)
LINK = $(LD)
LINK_EXTRAFLAGS = -no-undefined -version-info $(LIBGDAL_CURRENT):$(LIBGDAL_REVISION):$(LIBGDAL_AGE)
OBJ_EXT = lo
endif

OUTPUT = $(ROOTDIR_)/runtimes/$(RID)/native

CSHARP_MODULES = libgdalcsharp.$(SO_EXT) libogrcsharp.$(SO_EXT) libgdalconstcsharp.$(SO_EXT) libosrcsharp.$(SO_EXT)
CSHARP_OBJECTS = $(BASE)/const/gdalconst_wrap.$(OBJ_EXT) $(BASE)/gdal/gdal_wrap.$(OBJ_EXT)  $(BASE)/osr/osr_wrap.$(OBJ_EXT)  $(BASE)/ogr/ogr_wrap.$(OBJ_EXT)
echo:
	echo $(CXX)
clean:
	(cd $(BASE) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)
	(cd $(PWD) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)

veryclean: clean
	(cd $(BASE) && rm -f -R const/*.cs const/*.c gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs ogr/*.cpp Data)
	(cd $(PWD) && rm -f -R *.so *.o ./*.cs gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs *.c *.cpp .libs/ const/ ogr/ osr/ gdal/ obj/ runtimes/ bin/)
	
cleangdal:
	(cd $(BASE_GDAL_) && git clean -fdxq)
	
cleanpackages:
	(cd $(PWD) && rm -f -R $(NUGET_))
	
generate: interface

interface:
	$(MAKE) -f mkinterface

prebuild: interface 
	$(MAKE)  build
	
build: ${CSHARP_OBJECTS} ${CSHARP_MODULES} gdal_csharp

sign:
	(cd $(BASE) && sn -k gdal.snk)

install:
	@echo "No installation to be done"

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

linkall: clean_runtimes initdirs copygdalout copyprojout makesolocal copyalldepso 
	$(eval _so_out_:=$(wildcard  $(OUTPUT)/*.so*))
	$(foreach lib, $(_so_out_),  if [ -a $(lib) ]; then patchelf --set-rpath '$$ORIGIN' $(lib); fi;${\n})
	
clean_runtimes:
	rm -rvf $(OUTPUT)/*.* 
	
initdirs:
	mkdir -p $(OUTPUT)
	
copygdalout:
	cp -f ${GDAL_BASE_LIB}/libgdal.$(GDAL_SO_VER_) $(OUTPUT)/libgdal.$(GDAL_SO_VER_)
	
copyprojout:
	cp $(BASE_PROG_)/lib/*.so.15 $(OUTPUT)
makesolocal:
	$(eval local_o:=$(wildcard *.o))
	$(foreach lib, $(local_o),  g++ -shared -o $(OUTPUT)/$(basename $(lib)).so $(lib) $(OUTPUT)/libgdal.$(GDAL_SO_VER_);${\n})
	
copyalldepso:
	ldd $(GDAL_BASE_LIB)/libgdal.so | grep "=> /" | awk '{print $$3}' | xargs -I {} cp -v {} $(OUTPUT) 

gdal_csharp: 
	$(MAKE) linkall

hotfix31:	
	export MSBUILDSINGLELOADCONTEXT=1

packc: hotfix31
	dotnet pack -c Release -o $(NUGET_) $(ROOTDIR_)/gdalcore.loader.csproj	
	
packr: hotfix31
	dotnet pack -c Release -o $(NUGET_) $(ROOTDIR_)/gdalcore.linuxruntime.csproj
	
pack: packc packr

packdc: hotfix31
	dotnet pack -c Debug -o $(NUGET_) $(ROOTDIR_)/gdalcore.loader.csproj
	
packdr: hotfix31
	dotnet pack -c Debug -o $(NUGET_) $(ROOTDIR_)/gdalcore.linuxruntime.csproj
	
packdev: packdc packdr
	
