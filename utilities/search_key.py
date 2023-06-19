import struct
import sys

if len(sys.argv) < 3:
    print("\n\033[1;35m\tpython search_key.py <filename> <key>\033[0m")
    print("Search the key in <filename> file.")
    print("Passing 'min' as key returns the minimum, passing 'max' the maximum.\n")
    sys.exit()

filename = sys.argv[1]
key = sys.argv[2]

with open(filename, "rb") as f:
    # Read the number of pairs (uint64)
    num_pairs_bytes = f.read(8)
    num_pairs = struct.unpack('<Q', num_pairs_bytes)[0]

    if key == 'min':
        key_bytes = f.read(4)
        curr_key = struct.unpack('<I', key_bytes)[0]
        print("Minimum Key:", curr_key)
        exit(0)

    if key == 'max':
        f.seek(-8, 2)
        key_bytes = f.read(4)
        curr_key = struct.unpack('<I', key_bytes)[0]
        print("Maximum Key:", curr_key)
        exit(0)
    
    key = int(key)

    # Iterate over each pair and update min_key and max_key
    for i in range(num_pairs):
        # Read the key (uint32)
        key_bytes = f.read(4)
        _ = f.read(4)
        curr_key = struct.unpack('<I', key_bytes)[0]
        if curr_key == key:
            print(f"Found key {key} at position {i}!")
            exit(0)
        if curr_key > key:
            print(f"Key {key} is not here :(")
            exit(0)
