import sys
import struct
import argparse

# Thanks @ ChatGPT for this script!

def recover_substring(int_substring, l):
    mask_b = 3
    substring = ''
    for _ in range(l):
        basis = ''
        value = (int_substring & mask_b)
        if value == 0:
            basis = 'A'
        elif value == 1:
            basis = 'C'
        elif value == 2:
            basis = 'G'
        elif value == 3:
            basis = 'T'
        substring = basis + substring
        int_substring = int_substring >> 2
    return substring

parser = argparse.ArgumentParser(description='Visualize the content of keys and pos files generated from a reference string.')
parser.add_argument('filename', help='Specify the filename (mandatory)')
parser.add_argument('-n', '--num_entries', type=int, default=10, help='Number of entries (default: 10)')
direction_group = parser.add_mutually_exclusive_group()
direction_group.add_argument('-b', '--backward', action='store_true', help='Read backward (default: off)')
direction_group.add_argument('-f', '--forward', action='store_true', help='Read forward (default: on)')
args = parser.parse_args()

filename = args.filename
n_entries = args.num_entries
backward = args.backward
forward = args.forward

# Determine the configuration based on the filename
if filename.endswith("keys_uint32"):
    elem_size = 4
    format = '<I'
    pair = True
elif filename.endswith('pos_uint32'):
    elem_size = 4
    format = '<I'
    pair = False
elif filename.endswith("keys_uint64"):
    elem_size = 8
    format = 'Q'
    pair = True
else:
    print("Sorry, I don't know this file!\nAccepted files: keys_uint32, keys_uint64, pos_uint32")
    sys.exit()

print(f'🧬 Reading file {filename} 🧬')

with open(filename, "rb") as f:
    # first one
    chunk = f.read(8)
    N = struct.unpack("Q", chunk)[0]
    print('File length = ', N)
    # counter for the entries
    i = 0
    if forward:
        while i < n_entries and i < N:
            print(f'[{i}]', end=' ')
            chunk = f.read(elem_size)
            val1 = struct.unpack(format, chunk)[0]
            # if we are in pair mode, read again 32 bit
            if pair:
                chunk = f.read(4)
                val2 = struct.unpack('<I', chunk)[0]
                print(recover_substring(val1,elem_size*4), val2)
            else:
                print(val1)
            i += 1
    elif backward:
        if pair:
            full_size = elem_size + 4
        else:
            full_size = 4
        # move the pointer to the end
        f.seek(0, 2)
        # get position of the last entry
        pos_f = f.tell() - full_size
        while i < n_entries and i < N:
            print(f'[{N-i-1}]', end=' ')
            f.seek(pos_f)
            chunk = f.read(elem_size)
            val1 = struct.unpack(format, chunk)[0]
            # if we are in pair mode, read again 32 bit
            if pair:
                chunk = f.read(4)
                val2 = struct.unpack('<I', chunk)[0]
                print(recover_substring(val1,elem_size*4), val2)
            else:
                print(val1)
            i += 1
            pos_f -= full_size
