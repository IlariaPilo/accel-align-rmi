#!/bin/bash

ref_name=""
read_name=""
thread_number=$(nproc --all)
kmer_len=32
n=10

_source_dir_=$(dirname "$0")
RMI_DIR=$(readlink -f "$_source_dir_/..")

usage() {
    echo -e "\n\033[1;96mbash benchmarks.sh [OPTIONS] <reference.fa> <read.fastq>\033[0m"
    echo -e "Runs some benchmarks for accel-align (with/without rmi index)."
    echo -e "Executables should be already present (just run make)."
    echo -e "Indices should be built in advance (with proper -l option)."
    echo "Options:"
    echo "  -t, --threads  THREADS  The number of threads to be used [all]"
    echo "  -e, --exec     EXEC     The number of times every program is called [10]"
    echo "  -l, --len      LEN      The length of the kmer [32]"
    echo -e "  -h, --help              Display this help message\n"
    exit 1
}

# progress bar function taken from 
# https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
function ProgressBar {

    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done

    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

printf "\r${_fill// /▇}${_empty// / } ${_progress}%%"
[[ $_progress -eq 100 ]] && printf "\n"
}

# Parse command line options
while [[ $# -gt 2 ]]; do
    key="$1"
    case $key in
        -t|--threads)
            thread_number=$2
            shift 2
            ;;
        -l|--len)
            kmer_len=$2
            shift 2
            ;;
        -e|--exec)
            n=$2
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $key"
            usage
            ;;
    esac
done
# check reference genome
ref_name="$1"
if [ -z "$ref_name" ] || [ ! -e "$ref_name" ]; then
    echo -e "\033[1;31m [error!]\033[0m Please provide a valid reference genome file."
    usage
fi
ref_name=$(realpath $ref_name)              
# check read name
read_name="$2"
if [ -z "$read_name" ] || [ ! -e "$read_name" ]; then
    echo -e "\033[1;31m [error!]\033[0m Please provide a valid read file."
    usage
fi
read_name=$(realpath $read_name)              

# look for the accel-align-release directory
# assume there is only one of them, and is not further than 1 depths
RELEASE_DIR=$(find "$RMI_DIR/.." -type d -name "accel-align-release" | head -n 1)
if [ -z "$RELEASE_DIR" ]; then
    echo -e "\033[1;31m [error!]\033[0m accel-align-release direcotry not found :c"
    usage
fi
RELEASE_DIR=$(realpath $RELEASE_DIR)

echo -e "\n\033[1;96m [benchmarks.sh] \033[0m"
echo -e "       --- Found accel-align-release in \`$RELEASE_DIR\`."
echo -e "       --- kmer length is $kmer_len."
echo -e "       --- Running $n times, using $thread_number threads."

echo "---------------- BEGIN ----------------" > accel_align_rmi${kmer_len}.out
echo "Running $n times, using $thread_number threads." >> accel_align_rmi${kmer_len}.out

echo
echo "=========== accel-align-rmi ==========="
for ((i=0; i<n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> accel_align_rmi${kmer_len}.out
    "$RMI_DIR/accalign" -t $thread_number -l $kmer_len -o "rmi$kmer_len.sam" $ref_name $read_name 2>> accel_align_rmi${kmer_len}.out
done
ProgressBar $n $n
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-rmi execution completed.\n"
echo "----------------- END -----------------" >> accel_align_rmi${kmer_len}.out

# prepare the softlink for the index (if it exists)
if [ -e "$ref_name.hash$kmer_len" ]; then
    ln -s "$ref_name.hash$kmer_len" "$ref_name.hash" 
fi

echo "---------------- BEGIN ----------------" > accel_align_release${kmer_len}.out
echo "Running $n times, using $thread_number threads." >> accel_align_release${kmer_len}.out

echo
echo "========= accel-align-release ========="
for ((i=0; i<n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> accel_align_release${kmer_len}.out
    "$RELEASE_DIR/accalign" -t $thread_number -l $kmer_len -o "release$kmer_len.sam" $ref_name $read_name 2>> accel_align_release${kmer_len}.out
done
ProgressBar $n $n
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-release execution completed.\n"
echo "----------------- END -----------------" >> accel_align_release${kmer_len}.out

echo
# print some final considerations
echo -e "========= accel-align-rmi =========\t======= accel-align-release ======="
# time to align
cat accel_align_rmi${kmer_len}.out | grep "Time to align:" | awk '{ sum += $4 } END { avg = sum / NR; printf("Time to align: %.3f s\t\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "Time to align:" | awk '{ sum += $4 } END { avg = sum / NR; printf("Time to align: %.3f s\n", avg) }'
# lookup keyv time
cat accel_align_rmi${kmer_len}.out | grep "lookup keyv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup keyv time: %.3f s\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "lookup keyv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup keyv time: %.3f s\n", avg) }'
# lookup posv time
cat accel_align_rmi${kmer_len}.out | grep "lookup posv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup posv time: %.3f s\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "lookup posv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup posvv time: %.3f s\n", avg) }'
# hit count time
cat accel_align_rmi${kmer_len}.out | grep "Hit count" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Hit count time: %.3f s\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "Hit count" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Hit count time: %.3f s\n", avg) }'
# embedding
cat accel_align_rmi${kmer_len}.out | grep "Embedding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Embedding time: %.3f s\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "Embedding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Embedding time: %.3f s\n", avg) }'
# extending
cat accel_align_rmi${kmer_len}.out | grep "Extending" | awk '{ sum += $9 } END { avg = sum / NR; printf("Extending time: %.3f s\t\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "Extending" | awk '{ sum += $9 } END { avg = sum / NR; printf("Extending time: %.3f s\n", avg) }'
# mark best region
cat accel_align_rmi${kmer_len}.out | grep "Mark best region" | awk '{ sum += $5 } END { avg = sum / NR; printf("Mark best region time: %.3f s\t\t", avg) }'
cat accel_align_release${kmer_len}.out | grep "Mark best region" | awk '{ sum += $5 } END { avg = sum / NR; printf("Mark best region time: %.3f s\n", avg) }'
echo
