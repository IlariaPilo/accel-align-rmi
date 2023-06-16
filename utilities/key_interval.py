import struct
import sys

if len(sys.argv) < 2:
    print("\n\033[1;35m\tpython key_interval.py <filename>\033[0m")
    print("Prints the minimum and maximum keys in <filename> file.")
    sys.exit()

filename = sys.argv[1]

min_key = float('inf')
max_key = float('-inf')

with open(filename, "rb") as f:
    # Read the number of pairs (uint64)
    num_pairs_bytes = f.read(8)
    num_pairs = struct.unpack('<Q', num_pairs_bytes)[0]

    # Iterate over each pair and update min_key and max_key
    for i in range(num_pairs):
        # Read the key (uint32)
        key_bytes = f.read(4)
        _ = f.read(4)
        key = struct.unpack('<I', key_bytes)[0]
        if key < min_key:
            min_key = key
        if key > max_key:
            max_key = key

print("Minimum Key:", min_key)
print("Maximum Key:", max_key)
