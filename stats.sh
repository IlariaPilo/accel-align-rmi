#!/bin/bash

set -e

len=32
mod="2^29-1"
xxhash=0
ref=''
read=''

# Function to display usage instructions
usage() {
    echo -e "\n\033[1;96mbash stats.sh [OPTIONS] <reference.fna> <read.fastq>\033[0m"
    echo -e "Generates the precision stats for the default accel-align index."
    echo "Options:"
    echo "  -l  INT  length of the kmer [32]"
    echo "  -h  INT  value of hash MOD [2^29-1]"
    echo "           special string values = 2^29-1, prime, lprime"
    echo "  -x  INT  size of xxhash [0]"
    echo "           values = 0 (xxh not used), 32, 64"
    echo
    exit 1
}

make_stats() {
    # compile
    echo -e "\n\033[1;96m [stats.sh] \033[0mCompiling the required programs"
    make accindex stats

    # create the index
    echo -e "\n\033[1;96m [stats.sh] \033[0mGenerating the classic index"
    ./accindex -l $len -x $xxhash -h $mod $ref

    # run the stats
    echo -e "\n\033[1;96m [stats.sh] \033[0mRunning the 'stats' program"
    ./stats -l $len $ref $read
}

# read options from command line
while getopts ":lxh:" opt; do
    case $opt in
        l)
            len="$OPTARG"
            ;;
        h)
            mod="$OPTARG"
            ;;
        x)
            xxhash="$OPTARG"
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

index_out="${ref}.hash${len}" 
stats_out="${read}.stats${len}"

if [ ! -e $stats_out ]; then
  # The file does not exist, so create it
  make_stats
else
  # The file exists, so ask the user before executing
  read -ep $'\033[1;33m [stats.sh] \033[0mstats output already exists. Do you want to regenerate it? [y/N] ' choice
  case "$choice" in 
    y|Y )
      make_stats
      ;;
    * ) 
      echo -e "\033[1;33m [stats.sh] \033[0mCommand not executed" ;;
  esac
fi

# plot the charts
echo -e "\n\033[1;96m [stats.sh] \033[0mGenerating plots..."
python3 ./utilities/stats_analyzer.py $stats_out $len $(basename $ref) $(basename $read) $mod $xxh

# delete tmp file
read -ep $'\033[1;33m [stats.sh] \033[0mWould you like to remove the index file? [y/N] ' choice
case "$choice" in 
y|Y )
    rm $index_out
    echo -e "\033[1;33m [stats.sh] \033[0mIndex removed"
    ;;
* ) 
    echo -e "\033[1;33m [stats.sh] \033[0mIndex is still there!" ;;
esac

echo -e "\n\033[1;32m [stats.sh] \033[0mDone!\n"


