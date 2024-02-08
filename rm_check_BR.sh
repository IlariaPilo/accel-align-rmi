#!/bin/bash

function ProgressBar {

    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done

    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

printf "\r${_fill// /▇}${_empty// / } ${_progress}%%"
[[ $_progress -eq 100 ]] && printf "\n"
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 K"
    exit 1
fi

N=10000000
K=$1  # Number of times to repeat

check_files_equal() {
    if cmp -s "$1" "$2"; then
        echo -n
    else
        echo "Error: Files $1 and $2 have different content. Aborting."
        exit 1
    fi
}

# Loop K times
for ((i=0; i<K; i++)); do
    ProgressBar $i $K
    # Generate a random number between 0 and N-1
    random_number=$((RANDOM % N))

    # Calculate the range of lines to copy
    start_line=$((random_number * 4 + 1))
    end_line=$(((random_number + 1) * 4))

    # Copy the content to a temporary file
    sed -n -e "${start_line},${end_line}p" -e "${end_line}s/\n//" /home/ilaria/genomes/sv-10m-100-r.fastq > /home/ilaria/genomes/simulated.fq

    # try the program
    /home/ilaria/accel-align-rmi/accalign -B -t 46 -o tmp.sam /home/ilaria/genomes/hg37.fna /home/ilaria/genomes/simulated.fq 2> tmp.out
    cat tmp.out | grep \* > B.out
    /home/ilaria/accel-align-rmi/accalign -R -t 46 -o tmp.sam /home/ilaria/genomes/hg37.fna /home/ilaria/genomes/simulated.fq 2> tmp.out
    cat tmp.out | grep \* > R.out

    check_files_equal B.out R.out
done
ProgressBar $K $K

rm tmp.sam
rm tmp.out
rm B.out
rm R.out
echo "Script completed successfully!"
