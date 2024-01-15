#!/bin/bash

if [ $# -eq 0 ]; then
  echo -e "\n\033[1;96mbash run.sh <input_dir> \033[0m"
  echo -e "Runs the previously built container."
  echo -e "<input_dir> contains the <reference.fna> and <read.fastq> files."
  exit
fi

input_dir=$1
_source_dir_=$(dirname "$0")
BASE_DIR=$(readlink -f "${_source_dir_}/..")

input_dir=$(realpath $input_dir)

echo "Using input directory $input_dir"

docker run --rm -v $BASE_DIR:/home/aligner/accel-align-rmi \
    -v $input_dir:/home/aligner/accel-align-rmi/genomes \
    -it docker-align