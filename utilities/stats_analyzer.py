# 

# Imports
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys

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
PREFIX = FILE.rsplit('.')[0]
headless = False
if len(sys.argv) == 6:
    headless = True

def load():
    df = pd.read_csv(FILE)
    # Remove the entries where indexed_pos is 0
    df = df[df['indexed_pos']!=0]
    # Compute actual/indexed ratios
    df['ratio'] = df['actual_pos']/df['indexed_pos']
    return df

def make_hist(df):
    # Histogram
    plt.figure(figsize=(5, 3))
    plt.hist(df['ratio'], bins=50, weights=np.ones(len(df['ratio'])) / len(df['ratio']))
    plt.xlabel('Actual/Indexed Position Ratios')
    plt.ylabel('Ratios of Occurrences\n' 
            r'(Out of $10^7$)')
    plt.text(1, 1.05, f'{REF_NAME} [{LEN}] {READ_NAME}', fontsize=6.5, horizontalalignment='right', transform=plt.gca().transAxes)
    plt.grid(True)
    plt.savefig(f'{PREFIX}-hist-{LEN}.png', bbox_inches='tight')
    print(f'Histogram saved as {PREFIX}-hist-{LEN}.png')

def make_pie(df):
    def get_label(ratio):
        if ratio == 0:
            return '$r = 0$'
        if 0 < ratio <= 0.1:
            return '$0 < r \leq 0.1$'
        if 0.1 < ratio <= 0.2:
            return '$0.1 < r \leq 0.2$'
        if 0.2 < ratio <= 0.8:
            return '$0.2 < r \leq 0.8$'
        if 0.8 < ratio <= 1:
            return '$0.8 < r \leq 1$'
        assert(False)

    def get_order(label):
        if label=='$r = 0$':
            return 0
        if label=='$0 < r \leq 0.1$':
            return 1
        if label=='$0.1 < r \leq 0.2$':
            return 2 
        if label=='$0.2 < r \leq 0.8$':
            return 3
        if label=='$0.8 < r \leq 1$':
            return 4

    df['label'] = df['ratio'].apply(lambda x : get_label(x))
    label_counts_df = df['label'].value_counts().reset_index()
    label_counts_df.columns = ['label', 'count']
    label_counts_df['sort'] = label_counts_df['label'].apply(lambda x : get_order(x))
    label_counts_df = label_counts_df.sort_values(by='sort')

    # Pie chart
    plt.figure(figsize=(4, 4))
    plt.pie(label_counts_df['count'], labels=label_counts_df['label'], startangle=180, autopct='%1.1f%%', counterclock=False)
    not headless and plt.title(r'Precision $r$ for the positions'
            '\nreturned by the classic index.')
    plt.text(1.1, -0, f'{REF_NAME} [{LEN}] {READ_NAME}', fontsize=6.5, horizontalalignment='right', transform=plt.gca().transAxes)
    plt.savefig(f'{PREFIX}-pie-{LEN}.png', bbox_inches='tight')
    print(f'Pie saved as {PREFIX}-pie-{LEN}.png')

if __name__ == '__main__':
    df = load()
    make_hist(df)
    make_pie(df)
