#!/bin/bash

ref_name=""
read_name=""
thread_number=$(nproc --all)
kmer_len=32
n=10

_source_dir_=$(dirname "$0")
BASE_DIR=$(readlink -f "$_source_dir_/..")

OUT_DIR=$BASE_DIR

usage() {
    echo -e "\n\033[1;96mbash benchmarks.sh [OPTIONS] <reference.fa> <read.fastq>\033[0m"
    echo -e "Runs some benchmarks for accel-align (with/without rmi index)."
    echo -e "Executables should be already present (just run make)."
    echo -e "Indices should be built in advance (with proper -l option)."
    echo "Options:"
    echo "  -t, --threads  THREADS  The number of threads to be used [all]"
    echo "  -e, --exec     EXEC     The number of times every program is called [10]"
    echo "  -l, --len      LEN      The length of the kmer [32]"
    echo "  -o, --output   DIR      The directory where to save the output files [accel-align-rmi]"
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
        -o|--output)
            OUT_DIR=$2
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
# check output directory
OUT_DIR=$(realpath $OUT_DIR)
if [ ! -d $OUT_DIR ]; then
    echo "It looks like \`$OUT_DIR\` does not exists..."
    echo "Falling back to the default output directory!"
    OUT_DIR=$BASE_DIR
fi

echo -e "\n\033[1;96m [benchmarks.sh] \033[0m"
echo -e "       --- output directory is $OUT_DIR."
echo -e "       --- kmer length is $kmer_len."
echo -e "       --- Running $n times, using $thread_number threads."

echo "---------------- BEGIN ----------------" > $OUT_DIR/accel_align_rmi${kmer_len}.out
echo "Running $n times, using $thread_number threads." >> $OUT_DIR/accel_align_rmi${kmer_len}.out

echo
echo "=========== accel-align-rmi ==========="
for ((i=0; i<n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> $OUT_DIR/accel_align_rmi${kmer_len}.out
    "$BASE_DIR/accalign" -r -t $thread_number -l $kmer_len - o"$OUT_DIR/rmi$kmer_len.sam" $ref_name $read_name 2>> $OUT_DIR/accel_align_rmi${kmer_len}.out
done
ProgressBar $n $n
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-rmi execution completed.\n"
echo "----------------- END -----------------" >> $OUT_DIR/accel_align_rmi${kmer_len}.out

echo "---------------- BEGIN ----------------" > $OUT_DIR/accel_align_release${kmer_len}.out
echo "Running $n times, using $thread_number threads." >> $OUT_DIR/accel_align_release${kmer_len}.out

echo
echo "========= accel-align-release ========="
for ((i=0; i<n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> $OUT_DIR/accel_align_release${kmer_len}.out
    "$BASE_DIR/accalign" -t $thread_number -l $kmer_len - o"$OUT_DIR/release$kmer_len.sam" $ref_name $read_name 2>> $OUT_DIR/accel_align_release${kmer_len}.out
done
ProgressBar $n $n
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-release execution completed.\n"
echo "----------------- END -----------------" >> $OUT_DIR/accel_align_release${kmer_len}.out

echo
# print some final considerations
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m Printing average running times!\n"
echo -e "========= accel-align-rmi ========="
# time to align
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "Time to align:" | awk '{ sum += $4 } END { avg = sum / NR; printf("Time to align: %.3f s\n", avg) }'
# lookup keyv time
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "lookup keyv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup keyv time: %.3f s\n", avg) }'
# lookup posv time
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "lookup posv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup posv time: %.3f s\n", avg) }'
# hit count time
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "Hit count" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Hit count time: %.3f s\n", avg) }'
# embedding
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "Embedding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Embedding time: %.3f s\n", avg) }'
# extending
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "Extending" | awk '{ sum += $9 } END { avg = sum / NR; printf("Extending time: %.3f s\n", avg) }'
# mark best region
cat $OUT_DIR/accel_align_rmi${kmer_len}.out | grep "Mark best region" | awk '{ sum += $5 } END { avg = sum / NR; printf("Mark best region time: %.3f s\n", avg) }'
echo
echo -e "========= accel-align-release ========="
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "Time to align:" | awk '{ sum += $4 } END { avg = sum / NR; printf("Time to align: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "lookup keyv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup keyv time: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "lookup posv" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Lookup posv time: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "Hit count" | awk '{ sum += $4 } END { avg = sum / NR; printf("  Hit count time: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "Embedding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Embedding time: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "Extending" | awk '{ sum += $9 } END { avg = sum / NR; printf("Extending time: %.3f s\n", avg) }'
cat $OUT_DIR/accel_align_release${kmer_len}.out | grep "Mark best region" | awk '{ sum += $5 } END { avg = sum / NR; printf("Mark best region time: %.3f s\n", avg) }'
echo