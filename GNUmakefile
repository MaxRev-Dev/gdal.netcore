
# ---------------------- CONFIG ---------------------
##### GDAL source repo
$(eval _basegdal_=/mnt/e/dev/builds/gdal-source/gdal)

##### PROJ6 libraries path required by gdal
$(eval _baseproj_=/mnt/e/dev/builds/proj6-bin/lib/*.so.15)
# --------------------- !CONFIG! --------------------

$(eval _baseswig_=$(_basegdal_)/swig)
$(eval _basesrc_=$(_baseswig_)/csharp)
$(eval _outdir_=$(PWD))

# suppress warnings..
$(eval _suprf_=-Wno-missing-prototypes -Wno-missing-declarations -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-function)

include $(_basegdal_)/GDALmake.opt
include $(_baseswig_)/csharp/csharp.opt
define \n


endef
all: build

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
	(cd $(PWD) && rm -f -R *.so *.o *.cs *.c *.cpp .libs/ const/ ogr/ osr/ gdal/ obj/ runtimes/ bin/)
cleanpackages:
	(cd $(PWD) && rm -f -R nuget/)
generate: interface
interface:
	(cd $(_basesrc_) && ./mkinterface.sh)

build:  ${CSHARP_OBJECTS} ${CSHARP_MODULES} gdal_csharp	

sign:
	(cd $(_basesrc_) && sn -k gdal.snk)

install:
	@echo "No installation to be done"

$(CSHARP_MODULES): lib%csharp.$(SO_EXT): %_wrap.$(OBJ_EXT)
	$(LINK) $(LDFLAGS) $(CONFIG_LIBS) -Wl,-rpath '-Wl,$$ORIGIN'  $(_suprf_) $< -o $@ $(LINK_EXTRAFLAGS)

%.$(OBJ_EXT): %.cpp
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.cxx
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(_suprf_) -c $<

%.$(OBJ_EXT): %.c
	$(CC) $(CFLAGS) $(GDAL_INCLUDE)  $(_suprf_) -c $<

link_so:
	$(echo ok $< && patchelf --set-rpath '$$ORIGIN' $<)

gdal_csharp:
	$(eval _gdal_base_lib_=$(_basegdal_)/build/lib)
	$(eval _gdal_so_ver_=so.$(LIBGDAL_CURRENT))
	mkdir -p $(OUTPUT)
	rm -rvf $(OUTPUT)/*.* 
	cp -a $(_basesrc_)/const/. $(_outdir_)/const
	cp -a $(_basesrc_)/gdal/. $(_outdir_)/gdal
	cp -a $(_basesrc_)/osr/. $(_outdir_)/osr
	cp -a $(_basesrc_)/ogr/. $(_outdir_)/ogr
	cp -f ${_gdal_base_lib_}/libgdal.$(_gdal_so_ver_) $(OUTPUT)/libgdal.$(_gdal_so_ver_)
	cp -f lib*.so $(OUTPUT)
	cp $(_baseproj_) $(OUTPUT)
	mv $(OUTPUT)/libgdalconstcsharp.so $(OUTPUT)/gdalconst_wrap.so
	mv $(OUTPUT)/libogrcsharp.so $(OUTPUT)/ogr_wrap.so
	mv $(OUTPUT)/libosrcsharp.so $(OUTPUT)/osr_wrap.so	
	
	g++ -shared -o $(OUTPUT)/gdal_wrap.so gdal_wrap.o $(OUTPUT)/libgdal.$(_gdal_so_ver_)
		
	$(eval _o_out_=$(wildcard *.o))
	$(foreach lib, $(_o_out_),  g++ -shared -o $(OUTPUT)/$(basename $(lib)).so $(lib) $(OUTPUT)/libgdal.$(_gdal_so_ver_);${\n})
	
	$(eval _so_out_=$(wildcard $(OUTPUT)/*.so*))
	$(foreach lib, $(_so_out_),  if [ -a $(lib) ]; then patchelf --set-rpath '$$ORIGIN' $(lib); fi;${\n})
	
	ldd $(_gdal_base_lib_)/libgdal.so | grep "=> /" | awk '{print $$3}' | xargs -I {} cp -v {} $(OUTPUT) 

packc:
	dotnet pack -c Release -o $(_outdir_)/nuget $(_outdir_)/gdalcore.csproj
packr:
	dotnet pack -c Release -o $(_outdir_)/nuget $(_outdir_)/gdalcore-runtimes.csproj
pack: packc packr

packdc:
	dotnet pack -c Debug -o $(_outdir_)/nuget $(_outdir_)/gdalcore.csproj
packdr:
	dotnet pack -c Debug -o $(_outdir_)/nuget $(_outdir_)/gdalcore-runtimes.csproj
packdev: packdc packdr
	
