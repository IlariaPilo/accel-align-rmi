import sys
import struct

# Thanks @ ChatGPT for this script!

if len(sys.argv) < 2:
    print("\n\033[1;35m\tpython binary_print.py <filename> [<number_of_entries>]\033[0m")
    print("Prints the first \033[3mnumber_of_entries\033[0m entries of \033[3mfilename\033[0m file.")
    print("If \033[3mnumber_of_entries\033[0m is not specified, 10 entries are displayed.\n")
    sys.exit()

filename = sys.argv[1]
t = int(sys.argv[2]) if len(sys.argv) > 2 else 10  # set t to 10 if not provided

# Determine the element size based on the filename
if filename.endswith("uint32"):
    elem_size = 4
    format = '<I'
elif filename.endswith("uint64"):
    elem_size = 8
    format = 'Q'
else:
    print("Filename must end with 'uint32' or 'uint64'")
    sys.exit()

with open(filename, "rb") as f:
    # first one
    chunk = f.read(8)
    val = struct.unpack("Q", chunk)[0]
    print(val)
    # all the others
    for i in range(1, t):
        chunk = f.read(elem_size)
        if not chunk:  # stop if end of file
            break
        val = struct.unpack(format, chunk)[0]
        print(val)  # print the value

