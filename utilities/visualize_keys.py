import struct
import math
import os
import sys
import numpy as np
import matplotlib.pyplot as plt

def clean_filename(filename):
    # Remove _uint and everything that follows it
    if "_uint" in filename:
        filename = filename[:filename.index("_uint")]

    # Remove file extension
    filename = os.path.splitext(filename)[0]

    return filename

# Thanks @ ChatGPT for this script!

if len(sys.argv) < 2:
    print("\n\033[1;35m\tpython visualize_keys.py <filename>\033[0m")
    print("Prints the distribution of keys stored in the \033[3mfilename\033[0m file.\n")
    sys.exit()

# Define the file path
file_path = sys.argv[1]
clean_path = clean_filename(file_path)

# Read the first 8 bytes (64 bits) of the file to get the number of keys
with open(file_path, "rb") as f:
    num_keys = struct.unpack("q", f.read(8))[0]

# Calculate the number of bytes to read
num_bytes = num_keys * 4  # 4 bytes per key

# Read the rest of the file
with open(file_path, "rb") as f:
    f.seek(8)  # Skip the first 8 bytes
    data = np.fromfile(f, dtype=np.uint32, count=num_keys)

bins_number = round(1 + math.log2(num_keys))

# Plot the key distribution
plt.hist(data, bins=bins_number)
plt.title("Key Distribution")
plt.xlabel("Key")
plt.ylabel("Frequency")

plt.savefig(clean_path + "_distribution.jpg")
