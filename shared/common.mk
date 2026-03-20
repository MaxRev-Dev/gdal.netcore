#
# Common makefile targets shared between unix and osx platforms
#
# This file contains all duplicated target definitions that were previously
# maintained separately in unix/gdal-makefile and osx/gdal-makefile.
#

ifndef COMMON_MK_INCLUDED
COMMON_MK_INCLUDED := 1
unexport COMMON_MK_INCLUDED

SHELL=/bin/bash

# Build state and timing configuration
STATE_FILE=$(BUILD_ROOT)/.build-state.json

# Detect number of CPU cores
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
ifdef PARALLEL_JOBS
  NPROC := $(PARALLEL_JOBS)
endif
$(info $(LOG_PREFIX) Using $(NPROC) parallel jobs)

# lower and uppercase funcs
TARGET_UPPER  = $(shell echo '$*' | tr a-z A-Z)
TARGET_LOWER = $(shell echo '$*' | tr A-Z a-z)

# add support for [-force] param
TARGET_CLEAN = $(shell echo '$(TARGET_LOWER)' | sed "s/-force//g")

# target pretty output
TARGET_PREFIX = $(LOG_PREFIX) ${TARGET_UPPER} |

# Shared target definitions

clone_%:
	@if [ ! -d "$($(TARGET_UPPER)_ROOT)/.git" ]; then \
		$(GIT) clone $(GIT_CLONE_DEPTH) --single-branch -b $($(TARGET_UPPER)_COMMIT_VER) $($(TARGET_UPPER)_REPO) $($(TARGET_UPPER)_ROOT); \
	fi;

reset_%: clone_%
	@echo "$(TARGET_PREFIX) Restoring $(TARGET_LOWER) sources version to $($(TARGET_UPPER)_COMMIT_VER)"
	@echo "$(TARGET_PREFIX) Checking for remote changes..."
	@cd $($(TARGET_UPPER)_ROOT) && git fetch origin 'refs/tags/*:refs/tags/*' --force
	@cd $($(TARGET_UPPER)_ROOT) && git checkout -q tags/$($(TARGET_UPPER)_COMMIT_VER) --force || exit 1
	@echo "$(TARGET_PREFIX) Resetting sources..."
	@cd $($(TARGET_UPPER)_ROOT) && git reset --hard || exit 1
	@echo "$(TARGET_PREFIX) Cleaning the repo before compiling from scratch..."
	@cd $($(TARGET_UPPER)_ROOT) && $(GIT_CLEAN) || exit 1

remove_cache_%:
	@echo "$(TARGET_PREFIX) Removing build cache..."
	@if [[ -d "$($(TARGET_UPPER)_CMAKE_TMP)" ]]; then \
		rm -rf $($(TARGET_UPPER)_CMAKE_TMP) 2>/dev/null || rm -rf $($(TARGET_UPPER)_CMAKE_TMP)/* 2>/dev/null || true; \
	fi;

init_%: reset_% remove_cache_%
	@echo "$(TARGET_PREFIX) Sources restore complete"

check_state_%:
	@COMPONENT=$(TARGET_LOWER); \
	if [ -f "$(STATE_FILE)" ] && command -v jq >/dev/null 2>&1; then \
		LAST_VER=$$(jq -r ".$$COMPONENT.version // empty" $(STATE_FILE) 2>/dev/null); \
		LAST_HASH=$$(jq -r ".$$COMPONENT.hash // empty" $(STATE_FILE) 2>/dev/null); \
		CURRENT_VER=$($(TARGET_UPPER)_VERSION); \
		if [ -d "$($(TARGET_UPPER)_ROOT)" ]; then \
			CURRENT_HASH=$$(cd $($(TARGET_UPPER)_ROOT) && git rev-parse HEAD 2>/dev/null || echo "unknown"); \
		else \
			CURRENT_HASH="not-cloned"; \
		fi; \
		if [ "$$LAST_VER" = "$$CURRENT_VER" ] && [ -d "$(BUILD_ROOT)/$$COMPONENT-build" ] && \
		   ( [ "$$CURRENT_HASH" = "not-cloned" ] || [ "$$LAST_HASH" = "$$CURRENT_HASH" ] ); then \
			echo "$(LOG_PREFIX) ✓ $$COMPONENT is up to date (v$$CURRENT_VER), skipping build"; \
			exit 0; \
		else \
			echo "$(LOG_PREFIX) ⚠️  $$COMPONENT needs rebuild"; \
			[ "$$LAST_VER" != "$$CURRENT_VER" ] && echo "$(LOG_PREFIX)    Version: $$LAST_VER → $$CURRENT_VER"; \
			[ "$$CURRENT_HASH" != "not-cloned" ] && [ "$$LAST_HASH" != "$$CURRENT_HASH" ] && echo "$(LOG_PREFIX)    Hash: $${LAST_HASH:0:8} → $${CURRENT_HASH:0:8}"; \
			exit 1; \
		fi; \
	else \
		echo "$(LOG_PREFIX) ℹ️  No state file or jq not found, building $$COMPONENT"; \
		exit 1; \
	fi

save_state_%:
	@COMPONENT=$(TARGET_LOWER); \
	if command -v jq >/dev/null 2>&1; then \
		mkdir -p $(BUILD_ROOT); \
		CURRENT_VER=$($(TARGET_UPPER)_VERSION); \
		if [ -d "$($(TARGET_UPPER)_ROOT)" ]; then \
			CURRENT_HASH=$$(cd $($(TARGET_UPPER)_ROOT) && git rev-parse HEAD 2>/dev/null || echo "unknown"); \
		else \
			CURRENT_HASH="not-cloned"; \
		fi; \
		TIMESTAMP=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
		if [ -f "$(STATE_FILE)" ]; then \
			EXISTING=$$(cat $(STATE_FILE)); \
		else \
			EXISTING="{}"; \
		fi; \
		echo "$$EXISTING" | jq --arg comp "$$COMPONENT" \
			--arg ver "$$CURRENT_VER" \
			--arg hash "$$CURRENT_HASH" \
			--arg time "$$TIMESTAMP" \
			'.[$$comp] = {version: $$ver, hash: $$hash, built: $$time}' \
			> $(STATE_FILE).tmp && mv $(STATE_FILE).tmp $(STATE_FILE) && \
		echo "$(LOG_PREFIX) 💾 Saved state for $$COMPONENT (v$$CURRENT_VER)"; \
	fi

build_%:
	@echo "$(TARGET_PREFIX) $(TARGET_LOWER) Building with $(NPROC) parallel jobs..."
	@date +%s > /tmp/build_timer_$(TARGET_LOWER).txt
	@cd "$(BUILD_ROOT)/$(TARGET_LOWER)-cmake-temp" && cmake --build . -j$(NPROC) --target install || exit 1
	@if [ "$(TARGET_LOWER)" = "gdal" ] && [ -d "$(GDAL_CMAKE_TMP)/swig/csharp" ]; then \
		echo "$(TARGET_PREFIX) Persisting SWIG C# bindings to install dir..."; \
		mkdir -p $(GDAL_BUILD)/swig/csharp; \
		cd $(GDAL_CMAKE_TMP)/swig/csharp && \
		find . gdal ogr osr const -type f \( -name "*.$(LIB_EXT)" -o -name "*.cs" \) ! -path "*/bin/*" ! -path "*/obj/*" \
			-exec sh -c 'mkdir -p "$(GDAL_BUILD)/swig/csharp/$$(dirname "{}")" && cp "{}" "$(GDAL_BUILD)/swig/csharp/{}"' \; ; \
	fi
	@START=$$(cat /tmp/build_timer_$(TARGET_LOWER).txt 2>/dev/null || echo 0); \
	END=$$(date +%s); \
	DURATION=$$((END - START)); \
	echo "$(TARGET_PREFIX) $(TARGET_LOWER) was built successfully in $${DURATION}s!"; \
	mkdir -p $(BUILD_ROOT); \
	echo "$(TARGET_UPPER)=$${DURATION}" >> $(BUILD_ROOT)/.build-times.txt
	@$(MAKE) -f gdal-makefile save_state_$(TARGET_LOWER)

% :
	mkdir -p $(BUILD_ROOT)
ifneq ($(filter $(TARGET_CLEAN),$(TARGETS)),'')
	@echo "$(TARGET_PREFIX) trying to make stuff for => $(TARGET_CLEAN)"
	@if [[ "$(TARGET_LOWER)" == *"-force" ]]; then \
		echo "$(TARGET_PREFIX) Force rebuild requested"; \
		$(MAKE) -f gdal-makefile init_$(TARGET_CLEAN) || exit 1; \
		$(MAKE) -f gdal-makefile configure_$(TARGET_CLEAN) || exit 1; \
		$(MAKE) -f gdal-makefile build_$(TARGET_CLEAN) || exit 1; \
	elif $(MAKE) -f gdal-makefile check_state_$(TARGET_CLEAN) 2>/dev/null; then \
		echo "$(TARGET_PREFIX) Build is up to date, skipping"; \
	else \
		echo "$(TARGET_PREFIX) Build state changed, rebuilding"; \
		$(MAKE) -f gdal-makefile init_$(TARGET_CLEAN) || exit 1; \
		$(MAKE) -f gdal-makefile configure_$(TARGET_CLEAN) || exit 1; \
		$(MAKE) -f gdal-makefile build_$(TARGET_CLEAN) || exit 1; \
	fi;
else
	@echo "$(LOG_PREFIX) Can not make $(TARGET_CLEAN)"
endif

# HDF download targets
init_hdf: check_hdf_sources
	@echo "$(TARGET_PREFIX) HDF sources restore complete"

HDF_ZIP=hdf$(HDF_VERSION).zip
HDF_SOURCE=$(BUILD_ROOT)/hdf4-hdf$(HDF_VERSION)

download_hdf:
	@echo "$(TARGET_PREFIX) Downloading HDF source ${HDF_ZIP}..."
	$(LIB_PATH_VAR)="" curl -JL "https://github.com/HDFGroup/hdf4/archive/refs/tags/$(HDF_ZIP)" -o "$(BUILD_ROOT)/$(HDF_ZIP)"
	@echo "$(TARGET_PREFIX) HDF source downloaded!"
	@echo "$(TARGET_PREFIX) Extracting HDF source..."
	cd "$(BUILD_ROOT)"; unzip -oq "$(BUILD_ROOT)/$(HDF_ZIP)" -d .

check_hdf_sources:
	@if [[ ! -f "$(BUILD_ROOT)/$(HDF_ZIP)" ]] || [[ ! -d "$(HDF_SOURCE)" ]]; then \
		$(MAKE) -f gdal-makefile download_hdf; \
	fi;

# Convenience target for resetting all repositories
reset: reset_proj reset_gdal
	@echo "$(TARGET_PREFIX) Reset ALL is complete"

endif
