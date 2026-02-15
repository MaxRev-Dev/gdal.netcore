# Phase 2: Build System Consistency - Research

**Researched:** 2026-02-15
**Domain:** GNU Make build system refactoring and standardization
**Confidence:** HIGH

## Summary

Phase 2 aims to eliminate duplication and inconsistency between `unix/gdal-makefile` and `osx/gdal-makefile` by standardizing variable naming conventions and extracting shared logic into a common include file. The codebase currently has ~80% duplicated targets between platforms, unconventional variable names (trailing underscores, double-underscore prefixes, single-letter names), and no shared include mechanism—resulting in copy-paste drift where build state tracking and timing logic must be updated in two places.

The standard approach is to use GNU Make's `include` directive to source a `shared/common.mk` file containing duplicated targets, combined with platform-detection variables (e.g., `LIB_PATH_VAR` = `LD_LIBRARY_PATH` on unix, `DYLD_FALLBACK_LIBRARY_PATH` on osx) to handle the small platform-specific differences. Variable naming should follow GNU Coding Standards: UPPER_SNAKE_CASE for user-configurable parameters, lowercase_with_underscores for internal variables. Trailing underscores and double-underscore prefixes are unconventional and should be removed.

**Primary recommendation:** Extract identical targets (`%` wildcard, `clone_%`, `reset_%`, `remove_cache_%`, `check_state_%`, `save_state_%`, HDF init logic, `build_%` timing) to `shared/common.mk`, rename all variables to UPPER_SNAKE_CASE following GNU conventions, and use conditional variables for the few platform-specific differences (library paths, clone depth flags).

## Standard Stack

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GNU Make | 4.0+ | Build orchestration | Universal on unix-like systems, pattern rules and includes |
| Bash | 4.0+ | Shell scripting in targets | POSIX shell would work but bash features (arrays, conditionals) are widely available |
| jq | 1.5+ | JSON manipulation for build state | Standard JSON processor, already required in CI |

### Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `diff` | coreutils | Comparing makefiles for duplication | Pre-refactoring analysis |
| `grep` | GNU grep | Finding variable usage | Ensuring all renames are complete |
| `$(lastword $(MAKEFILE_LIST))` | Built-in Make | Robust relative includes | Always, prevents include path breakage |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GNU Make | Just/Task/CMake presets | More modern syntax but requires new dependency, migration risk too high (ROADMAP explicitly defers this) |
| Shared include | Template generation | More complex, harder to debug, no benefit over include |
| Manual variable sync | Leave as-is | Technical debt grows, copy-paste errors inevitable |

**Installation:**
No new tools required—GNU Make, Bash, and jq are already installed in CI and documented in unix/README.md and osx/README.md.

## Architecture Patterns

### Recommended Project Structure

Current structure (preserved):
```
shared/
├── GdalCore.opt          # Shared variables
├── common.mk             # NEW: Shared targets
unix/
├── RID.opt               # Platform-specific runtime identifier
├── gdal-makefile         # Platform-specific configure/format targets
├── vcpkg-makefile        # VCPKG package installation (minor diffs)
osx/
├── RID.opt               # Platform-specific runtime identifier
├── gdal-makefile         # Platform-specific configure/format targets
├── vcpkg-makefile        # VCPKG package installation (minor diffs)
```

### Pattern 1: Shared Include with Platform Detection

**What:** Extract duplicated targets to `shared/common.mk`, detect platform via Make conditionals, use platform-specific variables for differences.

**When to use:** When 80%+ of targets are identical across platforms with minor variations (library paths, command flags).

**Example:**
```makefile
# shared/common.mk
# Platform detection (if needed by shared targets)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LIB_PATH_VAR := DYLD_FALLBACK_LIBRARY_PATH
  CLONE_DEPTH_FLAG := $(GIT_CLONE_DEPTH) --single-branch -b $($(UP)_COMMIT_VER)
else
  LIB_PATH_VAR := LD_LIBRARY_PATH
  CLONE_DEPTH_FLAG :=
endif

# Shared targets
clone_%:
	@if [ ! -d "$($(UP)_ROOT)" ]; then \
		$(GIT) clone $(CLONE_DEPTH_FLAG) $($(UP)_REPO) $($(UP)_ROOT); \
	fi;

reset_%:
	@echo "$(LOG_PREFIX) $(TARGET_UPPER) | Restoring $(TARGET_LOWER) sources version to $($(UP)_COMMIT_VER)"
	@cd $($(UP)_ROOT) && git fetch origin 'refs/tags/*:refs/tags/*' --force
	@cd $($(UP)_ROOT) && git checkout -q tags/$($(UP)_COMMIT_VER) --force || exit 1
	@cd $($(UP)_ROOT) && git reset --hard || exit 1
	@cd $($(UP)_ROOT) && $(GIT_CLEAN) || exit 1
```

Source: Analysis of unix/gdal-makefile (lines 73-92) and osx/gdal-makefile (lines 79-92), combined with [GNU Make Include documentation](https://www.gnu.org/software/make/manual/html_node/Include.html).

### Pattern 2: Robust Relative Include Paths

**What:** Use `$(dir $(lastword $(MAKEFILE_LIST)))` to get the directory of the current makefile, enabling relative includes that work regardless of invocation directory.

**When to use:** Always, when including makefiles from different directories.

**Example:**
```makefile
# unix/gdal-makefile (top of file)
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(MAKEFILE_DIR)../shared/GdalCore.opt
include $(MAKEFILE_DIR)../shared/common.mk
```

Source: [SysTutorials - How to get a Makefile's directory](https://www.systutorials.com/how-to-get-a-makefiles-directory-for-including-other-makefiles/) and common GitHub patterns in [upbound/build](https://github.com/upbound/build/blob/master/makelib/common.mk).

### Pattern 3: Variable Naming Convention

**What:** UPPER_SNAKE_CASE for user-configurable parameters and environment variables, lowercase_with_underscores for makefile-internal variables.

**When to use:** All variable definitions.

**Example:**
```makefile
# User-configurable (can be overridden on command line)
BUILD_ROOT = $(ROOT_DIR)/build-$(BASE_RID)
VCPKG_ROOT = $(BUILD_ROOT)/vcpkg
PARALLEL_JOBS ?= $(shell nproc)

# Internal variables (lowercase, not meant for user override)
makefile_dir := $(dir $(lastword $(MAKEFILE_LIST)))
target_upper := $(shell echo '$*' | tr a-z A-Z)
target_lower := $(shell echo '$*' | tr A-Z a-z)
```

Source: [GNU Coding Standards - Makefile Conventions](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html) and [Makefile Style Guide](https://style-guides.readthedocs.io/en/latest/makefile.html).

### Anti-Patterns to Avoid

- **Trailing underscores (`ROOTDIR_`, `NUGET_`):** No semantic meaning, visually confusing, non-standard. Use full descriptive names like `ROOT_DIR`, `NUGET_DIR`.
- **Double-underscore prefixes (`__libshared`):** Reserved for system/internal use in many languages, unconventional in makefiles. Use descriptive names like `LIB_SHARED_NAME`.
- **Single-letter variable names (`UP`, `LW`, `TO`, `REP`):** Cryptic, hard to grep, maintenance burden. Use `TARGET_UPPER`, `TARGET_LOWER`, `TARGET_PREFIX`, `TARGET_CLEAN`.
- **Mixed case in constants (`HDF_zip`):** Inconsistent with UPPER_SNAKE_CASE convention. Use `HDF_ZIP`.
- **Typos that become API (`VPCKG_CUSTOM_TRIPLETS`):** Fix immediately—this is a typo for `VCPKG_CUSTOM_TRIPLETS`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recursive make coordination | Custom sub-make wrapper scripts | `include` directive + shared targets | GNU Make's include is designed for this; [Recursive Make Considered Harmful](https://www.oreilly.com/library/view/managing-projects-with/0596006101/ch06.html) recommends includes over recursion |
| Variable case conversion | Custom sed/awk scripts | `$(shell echo '$*' \| tr a-z A-Z)` | Standard Make idiom, already used in codebase |
| Platform detection | Complex uname parsing | `UNAME_S := $(shell uname -s)` + `ifeq` | Standard pattern from [cross-platform makefile guides](https://moldstud.com/articles/p-a-complete-guide-to-writing-cross-platform-makefiles-with-effective-dependency-management) |
| Dependency tracking | Manual timestamp files | Make's built-in prerequisites + `.build-state.json` with version/hash | Already implemented in check_state_%/save_state_%, more reliable than timestamps |

**Key insight:** GNU Make's include mechanism and conditional directives (ifeq/ifneq/ifdef/ifndef) are designed exactly for this use case—sharing logic across platforms while preserving platform-specific overrides. Building custom abstraraction layers is reinventing the wheel.

## Common Pitfalls

### Pitfall 1: Include Path Breakage on Relative Paths

**What goes wrong:** Using `include ../shared/common.mk` works when invoked from the makefile's directory but breaks when Make is invoked from a different working directory (e.g., `make -f unix/gdal-makefile` from repo root).

**Why it happens:** Relative paths in `include` are resolved from Make's current working directory, not the makefile's location.

**How to avoid:** Always use `$(dir $(lastword $(MAKEFILE_LIST)))` to get the makefile's directory:
```makefile
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(MAKEFILE_DIR)../shared/common.mk
```

**Warning signs:** `make: ../shared/common.mk: No such file or directory` when running make from different directories.

Source: [SysTutorials](https://www.systutorials.com/how-to-get-a-makefiles-directory-for-including-other-makefiles/), HIGH confidence (standard Make technique).

### Pitfall 2: Variable Rename Cascade Failures

**What goes wrong:** Renaming `ROOTDIR_` to `ROOT_DIR` in `shared/GdalCore.opt` but missing one usage in `osx/collect-deps-makefile` causes that platform's build to silently fail with cryptic errors (empty path, file not found).

**Why it happens:** `shared/GdalCore.opt` is included by every makefile. A variable rename affects 10+ files but no compiler catches it—Make silently treats undefined variables as empty strings.

**How to avoid:**
1. Before renaming, grep for ALL usages: `grep -r "ROOTDIR_" unix/ osx/ shared/ win/`
2. After renaming, grep to confirm zero old usages: `grep -r "ROOTDIR_" unix/ osx/ shared/ win/` should return nothing
3. Test builds on at least one platform before pushing
4. Let CI catch remaining issues across all platforms

**Warning signs:** Empty paths in echo statements, `mkdir: missing operand`, `cp: cannot stat ''`.

Source: Personal analysis of codebase variable usage, MEDIUM confidence (common refactoring hazard).

### Pitfall 3: Clone Strategy Divergence (Shallow vs Full)

**What goes wrong:** Unix makefiles use full `git clone` then `git checkout tags/X`, while osx uses `git clone --depth=1 --single-branch -b tags/X`. Unifying to shallow clone might break if the tag doesn't exist in the default branch's history, causing checkout failure.

**Why it happens:** Shallow clones only fetch the specified branch's history. If the tag is on a different branch, it won't be fetched.

**How to avoid:** Use the osx pattern (`--depth=1 --single-branch -b $($(UP)_COMMIT_VER)`) but test thoroughly. If checkout fails, fall back to shallow clone without `-b`, then fetch tags explicitly:
```makefile
clone_%:
	@if [ ! -d "$($(UP)_ROOT)" ]; then \
		$(GIT) clone $(GIT_CLONE_DEPTH) $($(UP)_REPO) $($(UP)_ROOT) && \
		cd $($(UP)_ROOT) && git fetch origin 'refs/tags/*:refs/tags/*' --force; \
	fi;
```

**Warning signs:** `fatal: Remote branch tags/vX.Y.Z not found in upstream origin` during clone.

Source: Analysis of unix/gdal-makefile (line 74) vs osx/gdal-makefile (line 81), MEDIUM confidence (git behavior well-documented but tag fetch varies by repo structure).

### Pitfall 4: Platform-Specific Variable Leakage

**What goes wrong:** Setting `LIB_PATH_VAR := LD_LIBRARY_PATH` in `shared/common.mk` without platform detection causes builds to fail on macOS, which requires `DYLD_FALLBACK_LIBRARY_PATH`.

**Why it happens:** Shared include files are sourced by both platforms, but some variables must differ by platform.

**How to avoid:** Use conditional assignment in `shared/common.mk`:
```makefile
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LIB_PATH_VAR := DYLD_FALLBACK_LIBRARY_PATH
else
  LIB_PATH_VAR := LD_LIBRARY_PATH
endif
```
Or define the variable in RID.opt (platform-specific) and reference it in common.mk.

**Warning signs:** `dyld: Library not loaded` errors on macOS, `error while loading shared libraries` on Linux.

Source: Comparison of unix/gdal-makefile (line 207) vs osx/gdal-makefile (line 217), HIGH confidence (documented difference).

### Pitfall 5: Forgetting to Update CI Cache Keys After Renames

**What goes wrong:** Renaming `shared/GdalCore.opt` variables doesn't break local builds but invalidates CI cache keys if workflows use `hashFiles('shared/GdalCore.opt')`. The hash changes, cache misses, but builds still succeed—defeating Phase 1's caching work.

**Why it happens:** CI cache keys are content-based. Any change to the hashed files invalidates the cache, even whitespace changes.

**How to avoid:** Variable renames in Phase 2 should NOT invalidate caches (they're refactoring, not functional changes). Solution: complete Phase 2 variable renames before Phase 1's cache tuning, OR accept one cache invalidation when Phase 2 merges.

**Warning signs:** CI builds suddenly slow down after Phase 2 merge, cache hit rate drops to 0%.

Source: `.github/workflows/macos.yml` (lines 57-82), `.github/workflows/unix.yml` (lines 53-78), MEDIUM confidence (standard CI cache behavior).

## Code Examples

Verified patterns from official sources and codebase analysis:

### Shared Include Pattern (Standard Approach)

```makefile
# shared/common.mk
# Guard against multiple inclusion (optional but recommended)
ifndef COMMON_MK_INCLUDED
COMMON_MK_INCLUDED := 1

# Platform detection for variables that differ
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LIB_PATH_VAR := DYLD_FALLBACK_LIBRARY_PATH
  GIT_CLONE_FLAGS := $(GIT_CLONE_DEPTH) --single-branch -b
else
  LIB_PATH_VAR := LD_LIBRARY_PATH
  GIT_CLONE_FLAGS :=
endif

# Shared targets (extracted from unix/gdal-makefile and osx/gdal-makefile)
clone_%:
	@if [ ! -d "$($(TARGET_UPPER)_ROOT)" ]; then \
		$(GIT) clone $(GIT_CLONE_FLAGS) $($(TARGET_UPPER)_COMMIT_VER) \
			$($(TARGET_UPPER)_REPO) $($(TARGET_UPPER)_ROOT); \
	fi;

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
		if [ "$$LAST_VER" = "$$CURRENT_VER" ] && [ "$$LAST_HASH" = "$$CURRENT_HASH" ] && [ -d "$(BUILD_ROOT)/$$COMPONENT-build" ]; then \
			echo "$(LOG_PREFIX) ✓ $$COMPONENT is up to date (v$$CURRENT_VER), skipping build"; \
			exit 0; \
		else \
			exit 1; \
		fi; \
	else \
		exit 1; \
	fi

endif # COMMON_MK_INCLUDED
```

Source: Extracted from unix/gdal-makefile (lines 223-246), combined with include guard pattern from [common.mk examples](https://github.com/mauve/common.mk/blob/master/common.mk).

### Robust Include in Platform Makefiles

```makefile
# unix/gdal-makefile (top of file, before other includes)
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include RID.opt
include $(MAKEFILE_DIR)../shared/GdalCore.opt
include $(MAKEFILE_DIR)../shared/common.mk

# Platform-specific state file location (already defined in GdalCore.opt via BUILD_ROOT)
STATE_FILE = $(BUILD_ROOT)/.build-state.json

# Platform-specific configure targets stay here
configure_gdal:
	@echo "$(LOG_PREFIX) $(TARGET_UPPER) | GDAL Configuring..."
	# ... platform-specific CMAKE flags ...
```

Source: Pattern from [SysTutorials](https://www.systutorials.com/how-to-get-a-makefiles-directory-for-including-other-makefiles/), applied to existing codebase structure.

### Variable Naming Refactor Example

**Before (unconventional):**
```makefile
# shared/GdalCore.opt
ROOTDIR_=$(BASE)/..
__libshared=maxrev.gdal.core.libshared
PRE=[gdal.netcore]
BASE_SWIG_=$(GDAL_ROOT)/swig
NUGET_=$(ROOTDIR_)/nuget
VPCKG_CUSTOM_TRIPLETS=$(VCPKG_ROOT)/custom-triplets
```

**After (GNU standard):**
```makefile
# shared/GdalCore.opt
ROOT_DIR = $(BASE)/..
LIB_SHARED_NAME = maxrev.gdal.core.libshared
LOG_PREFIX = [gdal.netcore]
SWIG_BASE = $(GDAL_ROOT)/swig
NUGET_DIR = $(ROOT_DIR)/nuget
VCPKG_CUSTOM_TRIPLETS = $(VCPKG_ROOT)/custom-triplets
```

Source: [GNU Coding Standards](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html) and [Makefile Style Guide](https://style-guides.readthedocs.io/en/latest/makefile.html).

### Platform-Conditional Variable Pattern

```makefile
# shared/common.mk (or RID.opt if more appropriate)
UNAME_S := $(shell uname -s)

# Library path variable (LD_LIBRARY_PATH on Linux, DYLD_FALLBACK_LIBRARY_PATH on macOS)
ifeq ($(UNAME_S),Darwin)
  LIB_PATH_VAR := DYLD_FALLBACK_LIBRARY_PATH
  LIB_EXT := dylib
else ifeq ($(UNAME_S),Linux)
  LIB_PATH_VAR := LD_LIBRARY_PATH
  LIB_EXT := so
else
  $(error Unsupported platform: $(UNAME_S))
endif
```

Source: [Cross-Platform Makefile Guide](https://moldstud.com/articles/p-a-complete-guide-to-writing-cross-platform-makefiles-with-effective-dependency-management), MEDIUM confidence.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Copy-paste targets across makefiles | Shared includes with platform conditionals | Industry standard since ~2000 | DRY principle, single source of truth |
| Recursive make (`make -C subdir`) | Include-based single makefile | [Peter Miller's paper, 1998](https://www.oreilly.com/library/view/managing-projects-with/0596006101/ch06.html) | Faster builds, better dependency tracking |
| Manual timestamp tracking | Content-hash + version tracking (`.build-state.json` with jq) | Modern approach (~2015+) | More reliable than mtime, handles version changes |
| Inconsistent variable naming | GNU Coding Standards (UPPER_SNAKE_CASE for public, lowercase for internal) | GNU Make conventions since 1.0 | Greppable, predictable, self-documenting |

**Deprecated/outdated:**
- **Recursive make for shared logic:** Still common but discouraged. "Recursive Make Considered Harmful" (Peter Miller, 1998) documents why includes are superior. Current codebase doesn't use recursive make (good), but has duplication (fixable with includes).
- **Single-letter variable names:** Common in 1980s makefiles due to screen width limits. Modern 100+ column displays and grep make this obsolete—descriptive names are always better.

## Open Questions

1. **Should platform-specific variables live in RID.opt or shared/common.mk?**
   - What we know: RID.opt is already platform-specific (unix/RID.opt vs osx/RID.opt). common.mk will be shared.
   - What's unclear: Whether `LIB_PATH_VAR` and `LIB_EXT` belong in RID.opt (platform file) or common.mk with `ifeq ($(UNAME_S),Darwin)` conditionals.
   - Recommendation: Put them in RID.opt—keeps common.mk truly platform-agnostic. RID.opt already handles `BASE_RID`, `VCPKG_RID`, etc., so adding `LIB_PATH_VAR` is consistent.

2. **How to handle the init_% target difference between platforms?**
   - What we know: unix uses `init_%: reset_% remove_cache_%` (dependencies), osx uses sequential Make calls inside the recipe.
   - What's unclear: Whether to unify or preserve this difference.
   - Recommendation: Unify to dependency-based (unix pattern). It's cleaner and lets Make handle parallelism. Test on both platforms.

3. **Should the HDF download logic stay or be replaced by git clone (Phase 3 scope)?**
   - What we know: Phase 3 (DEP-03) will migrate HDF4 to git clone. Phase 2 is about consistency, not dependency changes.
   - What's unclear: Whether to extract download_hdf/check_hdf_sources to common.mk now or wait for Phase 3.
   - Recommendation: Extract to common.mk in Phase 2 (it's duplicated), then Phase 3 can remove the entire block from one file instead of two.

## Sources

### Primary (HIGH confidence)

- **GNU Make Manual - Include:** https://www.gnu.org/software/make/manual/html_node/Include.html (official documentation on include directive)
- **GNU Coding Standards - Makefile Conventions:** https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html (official variable naming conventions)
- **Codebase Analysis:** Direct inspection of unix/gdal-makefile, osx/gdal-makefile, shared/GdalCore.opt (current state, duplication patterns)
- **ROADMAP.md Phase 2 Scope:** `.planning/ROADMAP.md` lines 80-163 (requirements, success criteria, affected files)

### Secondary (MEDIUM confidence)

- **Cross-Platform Makefiles Guide:** https://moldstud.com/articles/p-a-complete-guide-to-writing-cross-platform-makefiles-with-effective-dependency-management (platform detection patterns, verified against codebase needs)
- **Makefile Style Guide:** https://style-guides.readthedocs.io/en/latest/makefile.html (variable naming, lowercase for internal vars)
- **SysTutorials - Makefile Directory:** https://www.systutorials.com/how-to-get-a-makefiles-directory-for-including-other-makefiles/ (robust include path pattern)
- **O'Reilly - Managing Projects with GNU Make, Ch. 6:** https://www.oreilly.com/library/view/managing-projects-with/0596006101/ch06.html (include vs recursive make, large project patterns)
- **GitHub common.mk examples:** https://github.com/mauve/common.mk/blob/master/common.mk (include guard pattern)

### Tertiary (LOW confidence - informational only)

- **Wikipedia - Naming Conventions:** https://en.wikipedia.org/wiki/Naming_convention_(programming) (general background on UPPER_SNAKE_CASE)
- **Makefile Refactoring Blog Post:** https://mike-bland.com/2014/06/26/makefile-refactoring.html (refactoring strategies, not verified for accuracy)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - GNU Make, bash, jq are already in use and documented
- Architecture patterns: HIGH - Include directive and variable conventions are official GNU standards
- Pitfalls: MEDIUM-HIGH - Clone strategy and cache invalidation are project-specific inferences, others are standard refactoring hazards

**Research date:** 2026-02-15
**Valid until:** ~90 days (GNU Make standards stable, project structure unlikely to change rapidly)

---

## Planning Readiness

This research provides:
1. ✅ Standard approach: Include directive + shared targets + platform conditionals
2. ✅ Variable naming rules: UPPER_SNAKE_CASE for public, remove trailing/double underscores, fix typos
3. ✅ Duplication inventory: Specific targets to extract (%, clone_%, reset_%, etc.)
4. ✅ Platform differences catalog: LIB_PATH_VAR, LIB_EXT, clone flags, CMAKE options
5. ✅ Risk mitigation: Grep for old names, test on one platform, use robust include paths
6. ✅ Open questions answered: RID.opt for platform vars, unify init_% to dependencies, extract HDF logic now

**The planner has everything needed to create task-level PLAN.md files.**
