import json
import sys
import pandas as pd
import numpy as np

# Warning - this script is not supposed to be used alone, but just in the index pipeline process !
# Usage: model_select.py <optimizer_out path> <-p if we want to print the table>

def heuristic(df_configs):
    avg_err = df_configs['average log2 error']
    size_kb = df_configs['size']/(1024*8)
    # Look fot the lower error
    min_err = (avg_err)
    # Give each model a score
    
    return


# Get arguments
optimizer_path = sys.argv[1]
if optimizer_path == sys.argv[-1]:
    print_table = False
else:
    print_table = True

# Load the JSON data from the file
with open(optimizer_path, 'r') as f:
    data = json.load(f)


df = pd.DataFrame(data['configs'])

# Ask user which model do they want to build




# If nothing is provided, use heuristic







print(np.floor(df['average log2 error'])*np.log10(df['size']))
print(50331680/1024)