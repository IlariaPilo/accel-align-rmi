#!/bin/bash

echo "Downloading reference string"
wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz
gunzip human_g1k_v37.fasta.gz
sed -i '/^$/d' ./human_g1k_v37.fasta  #remove the empty line in the reference
mv human_g1k_v37.fasta hg37.fna