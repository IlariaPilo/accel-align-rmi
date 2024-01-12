#!/bin/bash

set -e

len=32
ref=''
read=''

# Function to display usage instructions
usage() {
    echo -e "\n\033[1;96mbash stats.sh [OPTIONS] <reference.fna> <read.fastq>\033[0m"
    echo -e "Generates the precision stats for the default accel-align index."
    echo "Options:"
    echo "  -l, --len      LEN     The length of the kmer. Default = 32"
    echo -e "  -h, --help             Display this help message\n"
    exit 1
}

# read options from command line
while getopts ":l:h" opt; do
    case $opt in
        l)
            len="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Shift the option arguments so that $1 and $2 now refer to the positional arguments
shift $((OPTIND-1))

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo -e "Error: Invalid number of arguments.\nPlease provide a <reference.fna> and a <read.fastq> file."
    usage
fi
ref="$1"
read="$2"
if [ ! -e "$ref" ]; then
    echo "Error: Please provide a valid reference genome file."
    usage
fi
if [ ! -e "$read" ]; then
    echo "Error: Please provide a valid read file."
    usage
fi

index_out="${ref}.hash" 
stats_out="${read}.stats${len}"

# compile
echo -e "\n\033[1;96m [stats.sh] \033[0mCompiling the required programs"
make accindex stats

# create the index
echo -e "\n\033[1;96m [stats.sh] \033[0mGenerating the classic index"
./accindex -l $len $ref

# run the stats
echo -e "\n\033[1;96m [stats.sh] \033[0mRunning the 'stats' program"
./stats -l $len $ref $read

# plot the charts




# delete tmp file
read -ep $'\033[1;33m [stats.sh] \033[0mWould you like to remove the index file? [y/N] ' choice
case "$choice" in 
y|Y )
    rm $index_out
    echo -e "\033[1;33m [stats.sh] \033[0mIndex removed"
    ;;
* ) 
    echo -e "\033[1;33m [stats.sh] \033[0mIndex NOT removed" ;;
esac

echo -e "\n\033[1;32m [stats.sh] \033[0mDone!\n"


