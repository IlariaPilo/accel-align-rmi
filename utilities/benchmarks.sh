#!/bin/bash

# max thread number T
T=$(nproc --all)

ref_name=""
read_name=""
thread_number=$T    # set to maximum number of threads
kmer_len=32
n=10
index="R"

numactl=false
numacmd=""

_source_dir_=$(dirname "$0")
BASE_DIR=$(readlink -f "$_source_dir_/..")

OUT_DIR=$BASE_DIR

usage() {
    echo -e "\n\033[1;96mbash benchmarks.sh [OPTIONS] <reference.fa> <read.fastq>\033[0m"
    echo -e "Runs some benchmarks for accel-align."
    echo -e "Executables should be already present (just run make)."
    echo -e "Indices should be built in advance (with proper -l option)."
    echo "Options:"
    echo "  -i, --index    IDX      The index to be used [R]"
    echo "                          Options = H (hash), B (binary), R (rmi)" 
    echo "  -t, --threads  THREADS  The number of threads to be used [all]"
    echo "  -e, --exec     EXEC     The number of times the program is called [10]"
    echo "  -l, --len      LEN      The length of the kmer [32]"
    echo "  -o, --output   DIR      The directory where to save the output files [accel-align-rmi]"
    echo "  -n, --numactl           Run using numactl to manage sockets [off]"
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
        -i|--index)
            index=$2
            shift 2
            ;;
        -n|--numactl)
            numactl=true
            shift 1
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
ref_name=$(realpath -se $ref_name)              
# check read name
read_name="$2"
if [ -z "$read_name" ] || [ ! -e "$read_name" ]; then
    echo -e "\033[1;31m [error!]\033[0m Please provide a valid read file."
    usage
fi
read_name=$(realpath -se $read_name)
# check output directory
OUT_DIR=$(realpath -se $OUT_DIR)
if [ ! -d $OUT_DIR ]; then
    echo "It looks like \`$OUT_DIR\` does not exists..."
    echo "Falling back to the default output directory!"
    OUT_DIR=$BASE_DIR
fi

if [ "$numactl" == true ]; then\
    echo "Running in \`numactl\` mode."
    socket_n=$(lscpu | grep Socket | awk '{print $NF}')
    # assume threads are equally distributed betweend sockets
    t_per_s=$((T / socket_n))
    echo " |- Server has $socket_n socket(s), $t_per_s threads per socket."
    # min(T, thread_number)
    needed_t=$((T < thread_number ? T : thread_number))
    # ceil(needed_t / t_per_s)
    needed_s=$(( (needed_t + t_per_s - 1) / t_per_s ))
    echo " |- Sockets needed = $needed_s"

    if [ "$needed_s" -eq 1 ]; then
        socket_interval="0"
    else
        socket_interval="0-$((needed_s - 1))"
    fi
    numacmd="numactl --cpunodebind $socket_interval --membind $socket_interval"

    echo " |- Socket interval = $socket_interval"
    echo " \`- numactl command : \`$numacmd\`"
fi

echo -e "\n\033[1;96m [benchmarks.sh] \033[0m"
echo -e "       --- index is $index."
echo -e "       --- output directory is $OUT_DIR."
echo -e "       --- kmer length is $kmer_len."
echo -e "       --- Running $n times, using $thread_number threads."

echo "---------------- BEGIN ----------------" > $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out
echo $numacmd >> $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out
echo "Running $n times, using $thread_number threads and index $index." >> $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out

echo
for ((i=0; i<n; i++))
do
    ProgressBar $i $n
    echo ">> $i <<" >> $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out
    $numacmd "$BASE_DIR/accalign" -${index} -t $thread_number -l $kmer_len -o "$OUT_DIR/${index}$kmer_len.sam" $ref_name $read_name 2>> $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out
done
ProgressBar $n $n
echo "----------------- END -----------------" >> $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out

bash $BASE_DIR/utilities/print_avg_time.sh $OUT_DIR/accel_align_${index}${kmer_len}-${thread_number}t.out
