import sys
import struct

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

if len(sys.argv) < 2:
    print("\n\033[1;35m\tpython binary_print.py <filename> [<direction>] [<number_of_entries>]\033[0m")
    print("Prints the entries of <filename> file.")
    print("If <number_of_entries> is not specified, 10 entries are displayed.")
    print("If <direction> is 'forward' or not provided, it reads from the beginning of the file.")
    print("If <direction> is 'backward', it reads from the end of the file.\n")
    sys.exit()

filename = sys.argv[1]
t = int(sys.argv[3]) if len(sys.argv) > 3 else 10  # set t to 10 if not provided
direction = sys.argv[2] if len(sys.argv) > 2 else 'forward'  # default direction is 'forward'

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

print(f'Begin reading file {filename}. Pair mode {"enabled" if pair else "disabled"}.')

with open(filename, "rb") as f:
    # first one
    chunk = f.read(8)
    N = struct.unpack("Q", chunk)[0]
    print('File length = ', N)

    # counter for the entries
    i = 0
    # FIXME up to now only forward
    while i < t and i < N:
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
        


    # if direction == 'backward':
    #     f.seek(0, 2)  # move the file pointer to the end of the file

    # # read and print the entries
    # i = 0
    # while i < t:
    #     if direction == 'backward':
    #         if i == 0:
    #             pos = f.tell() - elem_size 
    #         else:
    #             pos = f.tell() - elem_size*2 
    #         if pos < 0:  # stop if reached the beginning of the file
    #             break
    #         f.seek(pos)
    #     chunk = f.read(elem_size)
    #     if not chunk:  # stop if end of file
    #         break
    #     val = struct.unpack(format, chunk)[0]
    #     print(val)  # print the value
    #     i += 1
