from __future__ import division

import pandas as pd
import sys
import csv

base_skip = 26

if len(sys.argv) < 3:
    print("get_accuracy.py <real-results.sam> <aligned-results.sam> [<aligner-name>]")
    exit(1)

# ref_path = '/media/ssd/ngs-data-analysis/yan/input/10m-pe-1/sv-10m-100-pe-align.sam'
# align_path = '/media/ssd/ngs-data-analysis/yan/output/strobe.sam'
# output_path = '/media/ssd/ngs-data-analysis/yan/output/strobe.csv'
# aligner = 'strobe'
# match = 10

ref_path = str(sys.argv[1])
align_path = str(sys.argv[2])
output_path = align_path.replace(".sam", ".csv")
aligner = 'accalign' if len(sys.argv)==3 else str(sys.argv[3])
match = 10

print(f'Generating output file at `{output_path}`')

colName = ["QNAME", "FLAG", "RNAME", "POS"]
colIndex = [0, 1, 2, 3]

def get_distance(x):
    return abs(x["POS_x"] - x["POS_y"])

def get_skiprow(aligner):
    if aligner == "bwa" or aligner == "minimap2" or aligner == "mem2" or aligner == "strobe":
        return base_skip
    if aligner == "bowtie2" or aligner == "accalign" or aligner == "mrFast" or aligner == "fsva" or aligner == "subread":
        return base_skip+1
    if aligner == "snap":
        return base_skip+2

def clean_rname(rname):
    if rname.startswith('chr'):
        return rname[3:]
    return rname


ref = pd.read_csv(ref_path, sep = "\t", header = None, skiprows = base_skip, usecols= colIndex, names = colName, quoting=csv.QUOTE_NONE)
ref['RNAME'] = ref['RNAME'].apply(clean_rname)
#print(ref.head())

align = pd.read_csv(align_path, sep = "\t", header = None, skiprows = 86, usecols= colIndex, names = colName, quoting=csv.QUOTE_NONE)
align["QNAME"] = align["QNAME"].str.split('/').str[0]
#print(align.head())

## specially for minimap2, because it will produce multiple aligned places in sam file for one read
if aligner == "minimap2":
	align = align.groupby('QNAME').head(2).reset_index(drop=True)
	
aligned = align[align["RNAME"]!="*"]
#print(aligned.head())

merged = pd.merge(ref, aligned, how='inner', left_on=['QNAME', 'FLAG', 'RNAME'], right_on=['QNAME', 'FLAG', 'RNAME'])
#print(merged.head())

merged['diff'] = merged.apply(get_distance, axis=1)

total = len(ref)
counts = merged.groupby("diff").size()
df = counts.to_frame("count").reset_index()
df["percent"] = df["count"] / total * 100

res = df[df["diff"] < match]
other = df[df["diff"] >= match]
match_cnt = res["count"].sum()
not_align_cnt = len(align[align["RNAME"]=="*"])

cols = ['diff', 'count', 'percent']
df.to_csv(output_path, index = False)


exact_match = df[df["diff"] == 0]
exact_match_cnt = exact_match["count"].sum()
print("Total strands: ", total)
print("Not aligned(%):", not_align_cnt/total* 100)
print("Correctly aligned(%):", match_cnt/total* 100)
print("Exact aligned(%):", exact_match_cnt/total* 100)
