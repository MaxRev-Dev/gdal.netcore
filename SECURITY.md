# Security policy

This policy covers the `MaxRev.Gdal.*` NuGet packages published by this project.

## Supported versions

Security fixes focus on the latest released GDAL minor line, through new package
releases. Package versions track GDAL's version with an additional build number
(for example, `3.13.3.611`). Use the newest package release in that line.
Older GDAL minor lines do not receive routine security backports; please upgrade.
See the [release history](https://github.com/MaxRev-Dev/gdal.netcore/releases)
and [NuGet versions](https://www.nuget.org/packages/MaxRev.Gdal.Core/) for available versions.

## Report a vulnerability privately

Use GitHub's **Report a vulnerability** form in this repository's
[Security Advisories](https://github.com/MaxRev-Dev/gdal.netcore/security/advisories/new).
Please do not open a public issue for an undisclosed vulnerability in this project.

Include the affected package names and versions, operating system and architecture,
impact, reproduction steps or a minimal proof of concept, and any known upstream
advisory or fix. Share sensitive reproducers only in the private report.

## Scope and upstream dependencies

Reports about this project's .NET bindings and initialization code, build and
packaging scripts, or native libraries bundled in its packages are in scope.

For a flaw originating in [GDAL](https://github.com/OSGeo/gdal/security/policy),
[PROJ](https://github.com/OSGeo/PROJ), a native dependency, or a
[vcpkg port](https://github.com/microsoft/vcpkg/security/policy), also report it to
the relevant upstream project using its reporting guidance. Let us know privately
which packages are affected and link any existing upstream report or advisory;
avoid duplicating sensitive details publicly.

Upstream projects maintain their own fixes. This project ships those fixes by
updating dependency versions or pins and rebuilding affected packages, as with the
[libcurl](https://github.com/MaxRev-Dev/gdal.netcore/commit/55ffd9b17c9fadf9aadf3d21da0ed1e0c3f8bd00)
and [brotli](https://github.com/MaxRev-Dev/gdal.netcore/commit/ca7890dc9a81426a05409a0b6db68f4dc921dc9a)
security updates.

## What to expect

Maintainers will review the private report, ask for missing details, and assess
affected packages and upstream coordination needs. For confirmed issues, we aim
to coordinate a fix, a package release, and disclosure through a security advisory
as appropriate. Response and release timing depend on maintainer availability,
impact, and upstream fixes; no fixed response or remediation deadline is promised.
