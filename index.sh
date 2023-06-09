#!/bin/bash
set -e  # Stop if there is a failure
_redo_=0

################################### INTRO ###################################

# Check if the user has provided an argument
if [ $# -eq 0 ]; then
    echo -e "\n\033[1;35m\tbash index.sh <reference.fna> [<thread_number>]\033[0m"
    echo -e "Builds a learned index for the <reference.fna> reference string."
    echo -e "Use <thread_number> to specify the number of threads to be used. If not specified, it will be set to the number of available CPUs.\n"
    # TODO - echo -e "Pass _clean_ as second parameter to delete the index related to <reference.fna>.\n"
    exit
fi

INITIAL_DIR=$(pwd)
_source_dir_=$(dirname "$0")
BASE_DIR=$(readlink -f "$_source_dir_")     # /home/ilaria/Documents/uny/project/accel-align-rmi-dev
cd $BASE_DIR

ref_name=$1                                 # ./data/hg37.fna
ref_name=$(realpath $ref_name)
# The output file will be
dir_name=$(dirname $ref_name)               # ./data
base_name=$(basename $ref_name .fna)        # hg37

# Make output directory
OUTPUT_DIR="${dir_name}/${base_name}_index" # ./data/hg37_index
OUTPUT_DIR=$(realpath $OUTPUT_DIR)

mkdir -p $OUTPUT_DIR

keys_name="${OUTPUT_DIR}/keys_uint32"       # ./data/hg37_index/keys_unit32
pos_name="${OUTPUT_DIR}/pos_uint32"       # ./data/hg37_index/pos_unit32

# Get number of threads
if [ $# -eq 1 ]; then
  # Use default number
  thread_number=$(nproc --all)
else
  thread_number=$2
fi

echo -e "\n\033[1;35m [index.sh] \033[0mBuilding index on file $ref_name"
echo -e "            --- Using $thread_number threads.\n"


################################### KEY_GEN ###################################

echo -e "\n\033[1;35m [index.sh] \033[0mCompiling the key_gen program..."
make bin/key_gen


cd $OUTPUT_DIR                             # ----> NOW WE ARE IN hg37_index/keys_unit32

echo -e "\n\033[1;35m [index.sh] \033[0mRunning key_gen..."
if [ ! -e $keys_name ] || [ ! -e $pos_name ]; then
  # The file does not exist, so execute the command
  "${BASE_DIR}/bin/key_gen" $ref_name
else
  # The file exists, so ask the user before executing
  read -ep $'\033[1;33m [index.sh] \033[0mkey_gen output already exists. Do you want to execute the command anyway? [y/N] ' choice
  case "$choice" in 
    y|Y )
      _redo_=1 
      "${BASE_DIR}/bin/key_gen" $ref_name 
      ;;
    * ) 
      echo -e "\033[1;33m [index.sh] \033[0mcommand not executed" ;;
  esac
fi


################################### INDEX ###################################

echo -e "\n\033[1;35m [index.sh] \033[0mBuilding the index..."
# Build the index - if it has not being compiled yet
if ! [ -e "${BASE_DIR}/rmi/target/release/rmi" ] && ! [ -e ./rmi ]; then
  cd "${BASE_DIR}/rmi" && cargo build --release
  cd $OUTPUT_DIR
fi
if [[ ! -e ./rmi ]]; then
  # Copy it
  cp "${BASE_DIR}/rmi/target/release/rmi" .
fi

# Run RMI optimization - if not present
if [ ! -e optimizer.out ] || [ "$_redo_" == "1" ]; then
  # The file does not exist, so execute the command
  ./rmi --threads $thread_number --optimize optimizer.json ./keys_uint32 > optimizer.out
else
  # The file exists, so ask the user before executing
  read -ep $'\033[1;33m [index.sh] \033[0moptimizer output already exists. Do you want to execute the command anyway? [y/N] ' choice
  case "$choice" in 
    y|Y )
      _redo_=1  
      ./rmi --threads $thread_number --optimize optimizer.json ./keys_uint32 > optimizer.out
      ;;
    * ) 
      echo -e "\033[1;33m [index.sh] \033[0mcommand not executed" ;;
  esac
fi

# Print optimization result
cat optimizer.out

# Chose the best model and train it
# The chosen parameters in rmi_type.txt as type, branching_factor, size (KB), avg_log2_err
if [ ! -e rmi_type.txt ] || [ "$_redo_" == "1" ]; then
  # The file does not exist, so execute the command
  # Chose the best model somehow - TODO
  echo "NOT READY YET!"
else
  # The file exists, so ask the user before executing
  read type branching size avg_err max_err b_time < rmi_type.txt
  echo -e "\033[1;33m [index.sh] \033[0mmodel has already been chosen:"
  echo -e "               | MODEL\t\t\t$type"
  echo -e "               | BRANCHING FACTOR\t$branching"
  echo -e "               | SIZE (B)\t\t$size"
  echo -e "               | AVG LOG2 ERROR\t\t$avg_err"
  echo -e "               | MAX LOG2 ERROR\t\t$max_err"
  echo -e "               | BUILD TIME (ns)\t\t$b_time"
  read -ep $'            do you want to train a new one? [y/N] ' choice
  case "$choice" in 
    y|Y ) 
      _redo_=1 
      # Chose the best model somehow - TODO
      echo "NOT READY YET!"
      ;;
    * ) 
      echo -e "\033[1;33m [index.sh] \033[0mcommand not executed" ;;
  esac
fi

if [ ! -e rmi.h ] || [ "$_redo_" == "1" ]; then
  # Get the parameters
  read type branching _ _ _ _ < rmi_type.txt
  echo -e "\n\033[1;35m [index.sh] \033[0mTraining the $type ($branching) index"
  # Train the model
  ./rmi ./keys_uint32 rmi $type $branching
else
  echo -e "\n\033[1;35m [index.sh] \033[0mIndex already exists!\n"
fi
echo -e "\n\033[1;35m [index.sh] \033[0mDone!\n"


################################### SHARED OBJECT ###################################
# Copy Makefile in the current directory
if [ ! -e Makefile ]; then
  cp "${BASE_DIR}/rmi/Makefile" .
fi

# make ! -> create the shared library
make

cd $INITIAL_DIR