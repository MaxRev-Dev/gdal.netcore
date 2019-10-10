include GdalCore.opt
# ---------------------- CONFIG ---------------------
##### GDAL source location
$(eval _basegdal_=$(GDAL_ROOT)/gdal)

##### GDAL build location
$(eval _gdal_build_=$(BUILD_ROOT)/gdal-build)

##### PROJ6 libraries path required by gdal
$(eval _baseproj_=$(BUILD_ROOT)/proj6-build)
# --------------------- !CONFIG! --------------------

ifeq ($(LIBGDAL_CURRENT),)
LIBGDAL_CURRENT := 26
endif

ifeq ($(RID),)
RID=linux-x64
endif

$(eval _gdal_base_lib_=$(_gdal_build_)/lib)
$(eval _gdal_so_ver_=so.$(LIBGDAL_CURRENT))
$(eval _baseswig_=$(_basegdal_)/swig)
$(eval _basesrc_=$(_baseswig_)/csharp)
$(eval _outdir_=$(PWD))

# suppress warnings..
$(eval _suprf_=-Wno-missing-prototypes -Wno-missing-declarations -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-function)

include $(_basegdal_)/GDALmake.opt
include $(_baseswig_)/csharp/csharp.opt
define \n


endef
all: prebuild

BINDING = csharp
include SWIGmake.base

SWIGARGS = -DSWIG2_CSHARP -Wall -I$(_baseswig_)/include -I$(_baseswig_)/include/$(BINDING) 

LINK = $(LD_SHARED)
LINK_EXTRAFLAGS =
OBJ_EXT = o
ifeq ($(HAVE_LIBTOOL),yes)
LINK = $(LD)

LINK_EXTRAFLAGS = -no-undefined -version-info $(LIBGDAL_CURRENT):$(LIBGDAL_REVISION):$(LIBGDAL_AGE)

OBJ_EXT = lo
endif

OUTPUT = runtimes/$(RID)/native

CSHARP_MODULES = libgdalcsharp.$(SO_EXT) libogrcsharp.$(SO_EXT) libgdalconstcsharp.$(SO_EXT) libosrcsharp.$(SO_EXT)
CSHARP_OBJECTS = $(_basesrc_)/const/gdalconst_wrap.$(OBJ_EXT) $(_basesrc_)/gdal/gdal_wrap.$(OBJ_EXT)  $(_basesrc_)/osr/osr_wrap.$(OBJ_EXT)  $(_basesrc_)/ogr/ogr_wrap.$(OBJ_EXT)
echo:
	echo $(CXX)
clean:
	(cd $(_basesrc_) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)
	(cd $(PWD) && rm -f ${CSHARP_MODULES} *.$(OBJ_EXT) *.config *.dll *.mdb *.exe)

veryclean: clean
	(cd $(_basesrc_) && rm -f -R const/*.cs const/*.c gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs ogr/*.cpp Data)
	(cd $(PWD) && rm -f -R *.so *.o ./*.cs gdal/*.cs gdal/*.cpp osr/*.cs osr/*.cpp ogr/*.cs *.c *.cpp .libs/ const/ ogr/ osr/ gdal/ obj/ runtimes/ bin/)
	
cleangdal:
	(cd $(_basegdal_) && git clean -fdxq)
	
cleanpackages:
	(cd $(PWD) && rm -f -R nuget/)
	
generate: interface

interface:
	(cd $(_basesrc_) && ./mkinterface.sh)

prebuild: interface 
	$(MAKE)  build
	
build: ${CSHARP_OBJECTS} ${CSHARP_MODULES} gdal_csharp	

sign:
	(cd $(_basesrc_) && sn -k gdal.snk)

install:
	@echo "No installation to be done"

$(CSHARP_MODULES): lib%csharp.$(SO_EXT): %_wrap.$(OBJ_EXT)
	$(LINK) $(LDFLAGS) $(CONFIG_LIBS) -Wl,-rpath '-Wl,$$ORIGIN'  $(_suprf_) $< -o $@ $(LINK_EXTRAFLAGS) $(OUTPUT)/libgdal.$(_gdal_so_ver_)

%.$(OBJ_EXT): %.cpp
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.cxx
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.c
	$(CC) $(CFLAGS) $(GDAL_INCLUDE)  $(_suprf_) -c $<

link_so:
	$(echo ok $< && patchelf --set-rpath '$$ORIGIN' $<)

linkall: copywrappers clean_runtimes initdirs copygdalout copyprojout makesolocal copyalldepso 
	$(eval _so_out_:=$(wildcard  $(OUTPUT)/*.so*))
	$(foreach lib, $(_so_out_),  if [ -a $(lib) ]; then patchelf --set-rpath '$$ORIGIN' $(lib); fi;${\n})
	
clean_runtimes:
	rm -rvf $(OUTPUT)/*.* 
	
initdirs:
	mkdir -p $(OUTPUT)
	
copywrappers:
	cp -fr $(_basesrc_)/const $(_outdir_)/const
	cp -fr $(_basesrc_)/gdal $(_outdir_)/gdal
	cp -fr $(_basesrc_)/osr $(_outdir_)/osr
	cp -fr $(_basesrc_)/ogr $(_outdir_)/ogr
	
copygdalout:
	cp -f ${_gdal_base_lib_}/libgdal.$(_gdal_so_ver_) $(OUTPUT)/libgdal.$(_gdal_so_ver_)
	
copyprojout:
	cp $(_baseproj_)/lib/*.so.15 $(OUTPUT)
makesolocal:
	$(eval local_o:=$(wildcard *.o))
	$(foreach lib, $(local_o),  g++ -shared -o $(OUTPUT)/$(basename $(lib)).so $(lib) $(OUTPUT)/libgdal.$(_gdal_so_ver_);${\n})
	
copyalldepso:
	ldd $(_gdal_base_lib_)/libgdal.so | grep "=> /" | awk '{print $$3}' | xargs -I {} cp -v {} $(OUTPUT) 

gdal_csharp: 
	$(MAKE) linkall
	
packc: 
	dotnet pack -c Release -o $(_outdir_)/nuget $(_outdir_)/gdalcore.loader.csproj	
	
packr: 
	dotnet pack -c Release -o $(_outdir_)/nuget $(_outdir_)/gdalcore.linuxruntime.csproj
	
pack: packc packr

packdc:
	dotnet pack -c Debug -o $(_outdir_)/nuget $(_outdir_)/gdalcore.loader.csproj
	
packdr:
	dotnet pack -c Debug -o $(_outdir_)/nuget $(_outdir_)/gdalcore.linuxruntime.csproj
	
packdev: packdc packdr
	
