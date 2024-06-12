import os
import pandas as pd
import matplotlib.pyplot as plt
import regex as re
import sys

def parse_file(file_path):
    drivers = {}
    with open(file_path, "r") as file:
        for line in file:
            if " -raster" in line or " -vector" in line:
                match = re.match(
                    r"^\s*([A-Za-z0-9_]+)\s+-[A-Za-z, ]+-\s+\(([\w\+]+)\):", line
                )
                if match:
                    driver = match.group(1).strip()
                    capabilities = match.group(2).strip()
                    drivers[driver] = capabilities
    return drivers


def main(directory):
    data = {}
    all_drivers = set()

    for file_name in os.listdir(directory):
        if file_name.startswith("gdal-") and file_name.endswith(".txt"):
            parts = file_name.split("-")
            if len(parts) < 4:
                continue
            os_tag = parts[2]
            type_tag = parts[3].split(".")[0]
            key = f"{os_tag} ({type_tag})"
            file_path = os.path.join(directory, file_name)
            drivers = parse_file(file_path)
            data[key] = drivers
            all_drivers.update(drivers.keys())

    # Sort columns by type (raster, vector)
    sorted_keys = sorted(data.keys(), key=lambda x: ("vector" in x, x))

    table = pd.DataFrame(index=sorted(all_drivers), columns=sorted_keys)

    for key, drivers in data.items():
        for driver in all_drivers:
            table.loc[driver, key] = drivers.get(driver, "✗")

    save_table_as_markdown(table, os.path.join(directory, "supported_drivers.md"))


def save_table_as_markdown(table, output_path):
    note = """
**Note:**

- `r`: Read support
- `w`: Write support
- `+`: Update (read/write) support
- `v`: Supports virtual IO operations (like reading from `/vsimem`, `/vsicurl`, etc.)
- `s`: Supports subdatasets
- `o`: Optional features

Combining these abbreviations, you get:

- `ro`: Read-only support
- `rw`: Read and write support
- `rw+`: Read, write, and update support
- `rovs`: Read-only support with virtual IO and subdataset support
- `rw+v`: Read, write, update support with virtual IO
"""

    with open(output_path, "w") as file:
        file.write("# Supported GDAL Drivers\n")
        file.write(table.to_markdown())
        file.write("\n\n")
        file.write(note)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        print("Usage: python combine-formats.py <directory>")
        sys.exit(1)
    main(directory)
