# Contributing

Start focused changes from `main`, describe the problem and validation in your PR,
and include the platforms and architectures you tested. Build and dependency
changes need the relevant native builds and package tests before release.

## Repository layout and package flow

- `win/`: PowerShell and NMake build scripts for Windows x64.
- `unix/`: GNU Make scripts for Linux x64 and arm64; CI builds in Docker using
  [`ci/Dockerfile.unix`](ci/Dockerfile.unix).
- `osx/`: GNU Make scripts for macOS x64 and arm64.
- `shared/`: common versions in `GdalCore.opt`, the vcpkg manifest, registry
  configuration and lock, pinned SWIG configuration, CMake patch, package
  templates and MSBuild targets. `shared/common.mk` supplies
  shared Unix/macOS source checkout and build-state targets.
- `compile/`: managed loader, initialization and assembly validation sources.
- `tests/`: xUnit tests, console/CLI smoke applications, Azure Functions and
  .NET Framework examples, and generated driver inventories.
- `.github/workflows/`: `main.yml` calls the three platform workflows, gathers
  their artifacts, tests the Universal bundle, publishes packages and tags
  successful release builds on `main`.

Each platform builds PROJ, GDAL and its dependencies, generates C# bindings with
SWIG, collects native libraries and creates NuGet packages. Build trees live in
`build-win/`, `build-unix/` and `build-osx/`. Package templates under
`shared/templates/` produce projects and targets in `package-build/`; packages
go to `nuget/`. These output directories are gitignored and need not exist in a
fresh checkout.

`MaxRev.Gdal.Core` contains the managed bindings/loader and GDAL data; runtime
packages contain platform native libraries. Linux and macOS have architecture
packages plus bundles referencing both architectures. CLI packages reference
their runtime package. `MaxRev.Gdal.Universal` references Core and all runtime
packages. The central workflow uses the Linux x64 Core artifact as the canonical
Core package, including when other platforms also pack a copy.

## Local builds

Follow the prerequisites and commands in the existing platform guides, running
commands from the corresponding platform directory:

| Platform | Guide | Entry point after setup |
| --- | --- | --- |
| Windows x64 | [Windows prerequisites and build](win/README.md#prerequisites) | `./install.ps1` in PowerShell |
| Linux x64/arm64 | [Unix prerequisites and compilation](unix/README.md#prerequisites) | `make BUILD_ARCH=x64` or `make BUILD_ARCH=arm64` |
| macOS x64/arm64 | [macOS prerequisites and compilation](osx/README.md#prerequisites) | `make BUILD_ARCH=x64` or `make BUILD_ARCH=arm64` |

The Unix/macOS guides also show individual dependency, compile, collect, pack
and test steps. Their `RID.opt` files default to `arm64`, so pass `BUILD_ARCH`
explicitly for x64. Install the pinned SWIG with the platform setup script and
use the PATH setup documented there. The current shared configuration and CI
use .NET 10; Windows CI uses Visual Studio 2022 on `windows-2022`. Consult the
[Windows](.github/workflows/windows.yml), [Linux](.github/workflows/unix.yml) and
[macOS](.github/workflows/macos.yml) workflows for their exact build sequences
and tool setup. Windows native builds require a Windows environment.

## Commits and CI selection

Use Conventional Commits: `type(scope): description`, or `type: description`
when a scope adds no information. Scopes used in history include `win`, `unix`,
`osx`, `ci` and `deps`; examples include `fix(win): ...`, `fix(deps): ...`,
`ci: ...` and `docs: ...`.

Put CI tags in the commit subject, conventionally **at the end**:

| Tag | Use |
| --- | --- |
| `[ci skip]` | Documentation-only changes that need no build/test workflow. |
| `[skip unix]` | Skip Linux builds when the change cannot affect Linux. |
| `[skip windows]` | Skip Windows builds when the change cannot affect Windows. |
| `[skip osx]` | Skip macOS builds when the change cannot affect macOS. |

For example, a Windows-only change can end with `[skip unix] [skip osx]`.
Shared dependency, version, loader or packaging changes normally need all
platforms, so leave these tags off.

The OS parser in [main.yml](.github/workflows/main.yml) reads the checked-out
commit's subject with `git log -1 --pretty=format:"%s"`, including the PR head
commit for pull requests. Its case-sensitive regex is
`\[(skip|no) $os\]|\[$os skip\]` for `unix`, `windows` and `osx`; thus
`[no unix]` and `[unix skip]` are also accepted aliases. Prefer the tags in the
table. OS tags in older commits or the commit body do not select platforms. Check
the squash-merge subject too: copied PR commit messages in its body do not count.
`[ci skip]` is honored natively by GitHub in the head commit message; this
repository does not parse it. Keep it in the subject by convention as well.

## Updating GDAL, PROJ and dependencies

1. Change `GDAL_VERSION` and/or `PROJ_VERSION` in
   [`shared/GdalCore.opt`](shared/GdalCore.opt). GDAL source tags use
   `v$(GDAL_VERSION)`; PROJ tags use the bare version. Windows derives the same
   values from this shared file in `win/partials.psm1`.
2. Check that [`shared/patch/CMakeLists.txt.patch`](shared/patch/CMakeLists.txt.patch)
   still applies to the new GDAL C# CMake files. Review the native configuration
   in the platform makefiles and Windows scripts for upstream changes.
3. Rebuild, collect and pack for each supported platform/architecture, then test
   the resulting packages. Unix/macOS provide `proj-force` and `gdal-force`
   targets for a fresh rebuild; these reset and clean the upstream source
   checkouts inside the build tree.

Package versions are derived from the GDAL version, a build number and the
prerelease flag; see [`shared/bundle/base.opt`](shared/bundle/base.opt).
CI passes its run number as `BUILD_NUMBER_TAIL` (PowerShell: `-buildNumberTail`)
and uses the same values when testing the packages. Edit templates and shared
inputs rather than generated `package-build/` projects.

For a targeted vcpkg security fix, follow the libcurl (`55ffd9b`) and brotli
(`ca7890d`) pin commits:

- Add/update an `overrides` entry in [`shared/vcpkg.json`](shared/vcpkg.json)
  with the vcpkg port name, fixed `version` and appropriate `port-version`.
  The libcurl port is named `curl`; brotli can be pinned as a transitive
  dependency without adding it to each platform feature list.
- Update the registry `HEAD` in
  [`shared/vcpkg-lock.json`](shared/vcpkg-lock.json) to a vcpkg commit that
  contains that port version. Both examples kept the default registry baseline
  in `shared/vcpkg-configuration.json` and the tool checkout
  `VCPKG_COMMIT_VER` in `GdalCore.opt` unchanged.
- The platform wrappers synchronize the shared lock with the install root's
  `installed/vcpkg/vcpkg-lock.json`; review any lock changes after installing.
  Keep the shared manifest authoritative for all three platforms.
- Rebuild and test all affected packages. Preserve the Linux `GLIBC_FLOOR`
  configured in `GdalCore.opt` and enforced by
  [`ci/check-glibc-floor.sh`](ci/check-glibc-floor.sh). Explain the CVE, fixed
  version and validation in the PR, following `fix(deps): pin ...` history.

## GisInternals SDK mirror

Windows downloads `release-1930-x64-dev.zip` from the repository's
`deps-gisinternals-sdk` release first, falling back to GisInternals. CI caches
the pristine zip separately from build outputs. Follow the
[mirror refresh instructions](win/README.md#gisinternals-sdk-mirror) to run the
manual `Mirror GisInternals SDK` workflow or upload the asset. Set
`$script:SDK_ZIP_SHA256` in `win/partials.psm1` to the uploaded zip's checksum;
downloads and cached zips are verified against it. `SDK_MIRROR_URL` and `SDK_URL`
can override the download locations. The mirror release is a build dependency,
separate from project releases.

## Tests and driver inventories

Test the packages from `nuget/` after building. Use the same architecture,
build-number tail and prerelease settings as the pack step:

```powershell
# From win/; these values match ./install.ps1 defaults
./test.ps1 -buildNumberTail 10 -preRelease:$false
```

```bash
# From unix/ or osx/; these values match make BUILD_ARCH=arm64 defaults
make -f test-makefile test BUILD_ARCH=arm64 BUILD_NUMBER_TAIL=100 PRERELEASE=0
```

These entry points update package references, run the xUnit project under
`tests/MaxRev.Gdal.Core.Tests.XUnit/`, and run the CLI smoke application under
`tests/MaxRev.Gdal.Core.Tests.CLI/`. They modify test project package references;
review the working tree afterward and keep unrelated generated changes out of
your PR. CI tests Windows x64 and Linux/macOS x64 and arm64 packages, then tests
the assembled Universal bundle in `main.yml`.

Linux/macOS builds also verify bundled native names and dependencies; the
platform guides document `unique-native-names.sh verify ../nuget/*.nupkg`.
Windows packaging performs its DLL import checks in `win/partials.psm1`.

The `List of drivers in current version [ci skip]` commits are generated by
`main.yml` on pushes to `main`. It gathers the platform `formats-*` artifacts,
runs [`shared/scripts/combine-formats.py`](shared/scripts/combine-formats.py)
and commits `tests/gdal-formats/**`, including
[`supported_drivers.md`](tests/gdal-formats/supported_drivers.md). Driver
availability should come from those build outputs; change the build/dependency
configuration and let the workflow regenerate the inventory.
