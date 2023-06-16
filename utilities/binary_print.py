import sys
import struct

# Thanks @ ChatGPT for this script!

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
    print('Length: ', val)

    if direction == 'backward':
        f.seek(0, 2)  # move the file pointer to the end of the file

    # read and print the entries
    i = 0
    while i < t:
        if direction == 'backward':
            pos = f.tell() - elem_size
            if pos < 0:  # stop if reached the beginning of the file
                break
            f.seek(pos)
        chunk = f.read(elem_size)
        if not chunk:  # stop if end of file
            break
        val = struct.unpack(format, chunk)[0]
        print(val)  # print the value
        i += 1
