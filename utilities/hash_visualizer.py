# Thanks @ ChatGPT for this script!

import sys
import struct

hard_coded_mods = {
    1073741651: (1073741651,'prime'),
    2861333663: (2861333663,'lprime'),
    0: (4294967296, '2^32'),
    536870911: (536870911, '2^29-1')
}

def read_hash_file(file_path):
    try:
        with open(file_path, 'rb') as file:
            # Read the first 4 bytes and convert to unsigned int
            mod = struct.unpack('I', file.read(4))[0]
            # Read the next 4 bytes and convert to unsigned int
            xxh = struct.unpack('I', file.read(4))[0]
            return mod, xxh
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)
    except struct.error:
        print(f"Error: Unable to unpack bytes in '{file_path}'.")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 hash_visualizer.py <hash_file>")
        sys.exit(1)

    hash_file_path = sys.argv[1]
    mod, xxh = read_hash_file(hash_file_path)

    if (mod != 0 and mod < 128) or (xxh not in [0,32,64]):
        print('[warning] This is an old Accel-Align index')
        print('MOD = 2^29-1 [536870911]')
        print("No XXH")
        exit(0)

    # print MOD
    if mod in hard_coded_mods:
        mod, str_mod = hard_coded_mods[mod]
        print(f'MOD = {str_mod} [{mod}]')
    else:
        print(f'MOD = {mod}')
    # print XXH
    if xxh == 0:
        print("No XXH")
    else:
        print("XXH =", xxh)
