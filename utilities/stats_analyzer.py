# Imports
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
import os

# Plot configuration
plt.rcParams['figure.constrained_layout.use'] = True
plt.rcParams['grid.color'] = '#DDDDDD'
plt.rcParams['grid.linewidth'] = 0.8
plt.rcParams['text.usetex'] = False

# Read command line arguments
# python3 stats_analyzer.py STATS_FILE LEN REF_NAME READ_NAME [--headless]
if len(sys.argv) < 5:
    print("Usage : python3 stats_analyzer.py STATS_FILE KMER_LEN REF_NAME READ_NAME [--headless]")
    sys.exit()

FILE = sys.argv[1]
LEN = sys.argv[2]
REF_NAME = sys.argv[3]
READ_NAME = sys.argv[4]
PREFIX = os.path.abspath(FILE).rsplit('.')[0]
headless = False
has_reverse = False
if len(sys.argv) == 6:
    headless = True

def load():
    df = pd.read_csv(FILE)
    if 'indexed_pos_rev' in df.columns:
        has_reverse = True
        # Add the 'all' cases
        df['actual_pos_all'] = df['actual_pos_fwd']+df['actual_pos_rev']
        df['indexed_pos_all'] = df['indexed_pos_fwd']+df['indexed_pos_rev']
        # Compute actual/indexed ratios
        df['ratio_fwd'] = df['actual_pos_fwd']/df['indexed_pos_fwd']
        df['ratio_rev'] = df['actual_pos_rev']/df['indexed_pos_rev']
        df['ratio_all'] = df['actual_pos_all']/df['indexed_pos_all']
    else:
        # Compute actual/indexed ratios
        df['ratio_fwd'] = df['actual_pos_fwd']/df['indexed_pos_fwd']
    df.replace(np.nan, 0, inplace=True)
    return df, has_reverse

def make_hist(df, which_ratio='ratio_fwd', label='FWD'):
    # Histogram
    plt.figure(figsize=(5, 3))
    plt.hist(df[which_ratio], bins=50, weights=np.ones(len(df[which_ratio])) / len(df[which_ratio]))
    plt.xlabel(f'Actual/Indexed Position Ratios')
    plt.ylabel('Ratios of Occurrences\n' 
            r'(Out of $10^7$)')
    plt.text(1, 1.05, f'{REF_NAME} [{LEN}-{label}] {READ_NAME}', fontsize=6.5, horizontalalignment='right', transform=plt.gca().transAxes)
    plt.grid(True)
    plt.savefig(f'{PREFIX}-hist-{LEN}-{label}.png', bbox_inches='tight')
    print(f'Histogram saved as {PREFIX}-hist-{LEN}-{label}.png')

def make_pie(df, which_ratio='ratio_fwd', label='FWD'):
    def get_label(ratio):
        if ratio == 0:
            return '$r = 0$'
        if 0 < ratio <= 0.2:
            return '$0 < r \leq 0.2$'
        if 0.2 < ratio <= 0.4:
            return '$0.2 < r \leq 0.4$'
        if 0.4 < ratio <= 0.6:
            return '$0.4 < r \leq 0.6$'
        if 0.6 < ratio <= 0.8:
            return '$0.6 < r \leq 0.8$'
        if 0.8 < ratio <= 1:
            return '$0.8 < r \leq 1$'
        assert(False)

    def get_order(label):
        if label=='$r = 0$':
            return 0
        if label=='$0 < r \leq 0.2$':
            return 1
        if label=='$0.2 < r \leq 0.4$':
            return 2 
        if label=='$0.4 < r \leq 0.6$':
            return 3
        if label=='$0.6 < r \leq 0.8$':
            return 4
        if label=='$0.8 < r \leq 1$':
            return 5
        assert(False)

    df['label'] = df[which_ratio].apply(lambda x : get_label(x))
    label_counts_df = df['label'].value_counts().reset_index()
    label_counts_df.columns = ['label', 'count']
    label_counts_df['sort'] = label_counts_df['label'].apply(lambda x : get_order(x))
    label_counts_df = label_counts_df.sort_values(by='sort')

    # Pie chart
    plt.figure(figsize=(4, 4))
    plt.pie(label_counts_df['count'], labels=label_counts_df['label'], startangle=180, autopct='%1.1f%%', counterclock=False)
    not headless and plt.title(r'Precision $r$ for the positions'
            '\nreturned by the classic index.')
    plt.text(1.1, -0, f'{REF_NAME} [{LEN}-{label}] {READ_NAME}', fontsize=6.5, horizontalalignment='right', transform=plt.gca().transAxes)
    plt.savefig(f'{PREFIX}-pie-{LEN}-{label}.png', bbox_inches='tight')
    print(f'Pie saved as {PREFIX}-pie-{LEN}-{label}.png')

if __name__ == '__main__':
    df, has_reverse = load()
    # Default [FWD]
    make_hist(df)
    make_pie(df)
    if has_reverse:
        # Reverse
        make_hist(df, which_ratio='ratio_rev', label='REV')
        make_pie(df, which_ratio='ratio_rev', label='REV')
        # All
        make_hist(df, which_ratio='ratio_all', label='ALL')
        make_pie (df, which_ratio='ratio_all', label='ALL')
