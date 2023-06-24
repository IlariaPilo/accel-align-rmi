#!/bin/bash
set -e  # Stop if there is a failure

# README : move to /media/ssd/ilaria/

# Check if the user has provided an argument
if [ $# -eq 0 ]; then
    echo -e "\n\033[1;35m\tbash benchmark_local.sh <thread_number> [<number_of_executions>]\033[0m"
    echo -e "Runs some benchmarks for accel-align (with/witout rmi index)."
    echo -e "Indices should be built in advance (with -l 16 option)."
    echo -e "<thread_number> specifies the number of threads to be used."
    echo -e "<number_of_executions> is the number of times every program is called [default is 10]\n"
    exit
fi

# check if directories exist
if [[ ! -d "accel-align-rmi" ]] || [[ ! -d "accel-align-release" ]]; then
    echo -e "\n\033[1;31m [error]\033[0m the current directory does not contain the required projects (accel-align-rmi / accel-align-release)."
    echo -e "         Aborting...\n"
    exit
fi

thread_number=$1

# Get number of executions
if [ $# -eq 1 ]; then
  # Use default number
  n=10
else
  n=$2
fi

echo "============ accel-align-rmi ============"
for ((i=1; i<=n; i++))
do
    echo "Running iteration $i..."
    (/usr/bin/time --verbose ./accel-align-rmi/accalign -t $thread_number -l 16 \
    -o accalign_rmi.sam ./data/hg37.fna ./data/sv-10m-100-r.fastq \
    >> accel_align_rmi.out 2>&1)
done
echo -e "accel-align-rmi execution completed.\n"


echo "========== accel-align-release =========="
for ((i=1; i<=n; i++))
do
    echo "Running iteration $i..."
    (/usr/bin/time --verbose ./accel-align-release/accalign -t $thread_number -l 16 \
    -o accalign_release.sam ./data/hg37.fna ./data/sv-10m-100-r.fastq \
    >> accel_align_release.out 2>&1)
done
echo -e "accel-align-release execution completed.\n"