#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 K"
    exit 1
fi

N=10000000
K=$1  # Number of times to repeat

# Loop K times
for ((i=0; i<K; i++)); do
    # Generate a random number between 0 and N-1
    random_number=$((RANDOM % N))

    # Calculate the range of lines to copy
    start_line=$((random_number * 4 + 1))
    end_line=$(((random_number + 1) * 4))

    # Copy the content to a temporary file
    sed -n "${start_line},${end_line}p" /home/ilaria/genomes/sv-10m-100-r.fastq > temp_file_$i.txt

    echo "Copied content from lines ${start_line} to ${end_line} to temp_file_$i.txt"
done

echo "Script completed successfully!"
