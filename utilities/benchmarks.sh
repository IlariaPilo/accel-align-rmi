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
    echo "  -l, --len      LEN      The length of the kmer. [32]"
    echo -e "  -h, --help              Display this help message\n"
    exit 1
}

# progress bar function taken from 
# https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
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
read_name="$1"
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

echo "---------------- BEGIN ----------------" >> accel_align_rmi.out
echo "Running $n times, using $thread_number threads." >> accel_align_rmi.out

echo
echo "=========== accel-align-rmi ==========="
for ((i=1; i<=n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> accel_align_rmi.out
    "$RMI_DIR/accalign" -t $thread_number -l $kmer_len -o "rmi$kmer_len.sam" $ref_name $read_name 2>> accel_align_rmi.out
done
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-rmi execution completed.\n"
echo "----------------- END -----------------" >> accel_align_rmi.out

echo "---------------- BEGIN ----------------" >> accel_align_release.out
echo "Running $n times, using $thread_number threads." >> accel_align_release.out

echo
echo "========= accel-align-release ========="
for ((i=1; i<=n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> accel_align_release.out
    "$RELEASE_DIR/accalign" -t $thread_number -l $kmer_len -o "release$kmer_len.sam" $ref_name $read_name 2>> accel_align_release.out
done
echo -e "\n\033[1;32m [benchmarks.sh]\033[0m accel-align-release execution completed.\n"
echo "----------------- END -----------------" >> accel_align_release.out

# print some final considerations FIXME TODO
echo -e "  ========= accel-align-rmi =========\t\t  ======= accel-align-release ======="
cat accel_align_rmi.out | grep "Total time" | awk '{ sum += $3 } END { avg = sum / NR; printf("Total time (avg): %d secs [%02d:%02d min]\t\t", avg, avg/60, avg%60) }'
cat accel_align_release.out | grep "Total time" | awk '{ sum += $3 } END { avg = sum / NR; printf("Total time (avg): %d secs [%02d:%02d min]\n", avg, avg/60, avg%60) }'
cat accel_align_rmi.out | grep "keyv time" | awk '{ sum += $4 } END { avg = sum / NR; printf("Lookup keyv time (avg): %.3f secs\t\t", avg) }'
cat accel_align_release.out | grep "keyv time" | awk '{ sum += $4 } END { avg = sum / NR; printf("Lookup keyv time (avg): %.3f secs\n\n", avg) }'