include RID.opt
include ../shared/GdalCore.opt
include $(GDAL_ROOT)/swig/csharp/csharp.opt
 
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

interface:
	$(MAKE) -f ./generate-interface-makefile

build: interface linkall
	@echo "Bindings and drivers are ready to packaging!"

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
#   include all deps installed in this repo
#   and some external dependencies (odbc,ltdl)
	ldd "$(BUILD_BASE_LIB)/libgdal.so" | grep -E "$(ROOTDIR_)/build-unix|odbc|ltdl" | awk '{print $$3}' | xargs -I {} cp -v {} $(OUTPUT) 
	
copyprojdb:
	-mkdir -p $(LIBSHARED)
	cp -f $(BASE_PROJ)/share/proj/proj.db $(LIBSHARED)
