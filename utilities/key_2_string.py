import sys
import numpy as np

if len(sys.argv) < 2:
    #print("\n\033[1;35m\tpython key_2_string.py <key> [<len>]\033[0m")
    print("\n\033[1;35m\tpython key_2_string.py <key>\033[0m")
    print("Takes the key and converts it into a kmer, assuming its length is 16.")
    #print("<len> is the kmer length. Default value is 16. Supported values are 16 and 32.\n")
    sys.exit()

key = np.uint32(sys.argv[1])

try:
    len_ = sys.argv[2]
except:
    len_ = 16

kmer = ''
code = {
    0: 'A',
    1: 'C',
    2: 'G',
    3: 'T'
}
# A -> 0
# C -> 1
# G -> 2
# T -> 3

for i in range(16):
    k_i = key >> 2*i
    letter = k_i & 3
    kmer += code[letter]

print(kmer)