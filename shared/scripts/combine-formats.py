import os
import pandas as pd
import matplotlib.pyplot as plt
import sys

def parse_file(file_path):
    drivers = set()
    with open(file_path, 'r') as file:
        for line in file:
            if 'raster' in line or 'vector' in line:
                driver = line.strip().split(' ')[0].strip()
                drivers.add(driver)
    return drivers

def main(directory):
    data = {}
    all_drivers = set() 

    for file_name in os.listdir(directory):
        if file_name.endswith(".txt"):
            parts = file_name.split('-')
            os_tag = parts[2]
            if (len(parts) < 4): continue
            type_tag = parts[3].split('.')[0]
            key = f"{os_tag} ({type_tag})"
            file_path = os.path.join(directory, file_name)
            drivers = parse_file(file_path)
            data[key] = drivers
            all_drivers.update(drivers)
            
    sorted_keys = sorted(data.keys(), key=lambda x: ('vector' in x, x))
    table = pd.DataFrame(index=sorted(all_drivers), columns=sorted_keys)

    for key, drivers in data.items():
        table[key] = ['✓' if driver in drivers else '✗' for driver in table.index]

    save_table_as_markdown(table, os.path.join(directory, 'supported_drivers.md'))

def save_table_as_markdown(table, output_path):
    with open(output_path, 'w') as file:
        file.write(table.to_markdown())

if __name__ == "__main__":
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        print("Usage: python combine-formats.py <directory>")
        sys.exit(1)
    main(directory)