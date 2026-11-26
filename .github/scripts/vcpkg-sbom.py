"""Inventory vcpkg's resolved plans without compiling native dependencies.

The versioned vcpkg CLI emits one package per indented plan row. Reject empty
plans and missing direct dependencies so format drift cannot silently omit them.
Generic PURLs retain vcpkg identity; they do not claim an OSV ecosystem mapping.
Built-in triplets approximate the shipped port set: release builds use custom
release-only triplets. These plans are not SBOMs of built release binaries.
"""

import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import quote
import uuid


def main():
    vcpkg_root = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    manifest_root = Path("shared").resolve()
    manifest = json.loads((manifest_root / "vcpkg.json").read_text())
    configuration = json.loads((manifest_root / "vcpkg-configuration.json").read_text())
    baseline = configuration["default-registry"]["baseline"]
    platform_filter = sys.argv[3]
    actual = subprocess.check_output(
        ["git", "-C", str(vcpkg_root), "rev-parse", "HEAD"], text=True
    ).strip()
    if actual != baseline:
        raise ValueError("vcpkg checkout must match the manifest registry baseline")
    for name in ("vcpkg.json", "vcpkg-configuration.json", "vcpkg-lock.json"):
        shutil.copyfile(manifest_root / name, output / name)

    components = {}
    row = re.compile(
        r"^\s+(?:\* )?([a-z0-9-]+)(?:\[[^\]]+\])?:([a-z0-9-]+)@([^\s]+)"
    )
    profiles = {
        "linux-dynamic": "linux",
        "osx-dynamic": "osx",
        "osx-static-tools": "osx",
        "windows-dynamic": "windows",
    }
    if platform_filter not in profiles.values():
        raise ValueError(f"Unknown platform: {platform_filter}")
    for feature, platform in profiles.items():
        if platform != platform_filter:
            continue
        for arch in ("x64", "arm64"):
            triplet = f"{arch}-{platform}"
            profile = f"{feature}-{arch}"
            install_root = output / "installed" / profile
            lock_root = install_root / "vcpkg"
            lock_root.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(manifest_root / "vcpkg-lock.json", lock_root / "vcpkg-lock.json")
            command = [
                str(vcpkg_root / ("vcpkg.exe" if os.name == "nt" else "vcpkg")), "install", "--dry-run",
                f"--x-manifest-root={manifest_root}",
                f"--x-install-root={install_root}",
                f"--triplet={triplet}",
                "--x-no-default-features", f"--x-feature={feature}",
            ]
            result = subprocess.run(
                command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                env={**os.environ, "VSLANG": "1033", "VCPKG_DISABLE_METRICS": "1"},
            )
            (output / f"{profile}.txt").write_text(result.stdout)
            if result.returncode:
                raise RuntimeError(result.stdout)
            packages = [match.groups() for line in result.stdout.splitlines()
                        if (match := row.match(line))]
            candidate_rows = [line for line in result.stdout.splitlines()
                              if line.startswith("  ") and "@" in line]
            if len(packages) != len(candidate_rows):
                raise ValueError(f"Unparsed package rows in {profile}")
            direct = {dep if isinstance(dep, str) else dep["name"]
                      for dep in manifest["features"][feature]["dependencies"]}
            resolved = {name for name, target, _ in packages if target == triplet}
            if not packages or not direct.issubset(resolved):
                raise ValueError(f"Incomplete plan for {profile}: {direct - resolved}")
            for name, target, version in packages:
                purl = f"pkg:generic/vcpkg/{name}@{quote(version, safe='')}?triplet={target}"
                component = components.setdefault(purl, {
                    "type": "library", "bom-ref": purl, "name": name,
                    "version": version, "purl": purl, "properties": [],
                })
                component["properties"].append({"name": "vcpkg:profile", "value": profile})
            print(f"{profile}: {len(packages)} resolved packages")

    bom = {
        "bomFormat": "CycloneDX", "specVersion": "1.6", "version": 1,
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "metadata": {
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "properties": [
                {"name": "vcpkg:baseline", "value": baseline},
                {"name": "vcpkg:coverage", "value": "Built-in triplets approximate custom release-only triplets; native host tools; not built release binaries"},
            ],
        },
        "components": [components[key] for key in sorted(components)],
    }
    (output / "bom.cdx.json").write_text(json.dumps(bom, indent=2) + "\n")
    # Dry runs should not install packages; omit their bookkeeping directories.
    shutil.rmtree(output / "installed", ignore_errors=True)


if __name__ == "__main__":
    main()
