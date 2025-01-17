#!/bin/bash
set -e

if [ $# -eq 0 ]; then
  echo -e "\n\033[1;96mbash run.sh <input_dir> \033[0m"
  echo -e "Runs the previously built container."
  echo -e "<input_dir> contains the <reference.fna> and <read.fastq> files."
  exit
fi

input_dir=$1
_source_dir_=$(dirname "$0")
BASE_DIR=$(readlink -f "${_source_dir_}/..")

input_dir=$(realpath -se $input_dir)

if [ ! -d $input_dir ]; then
    echo "It looks like \`$input_dir\` does not exists..."
    echo "Aborting!"
    exit 1
fi

echo "Mounting directory $input_dir in \`/home/accel-align-rmi/genomes\`."

docker run --rm -v $BASE_DIR:/home/accel-align-rmi \
    -v ./.bash_history:/root/.bash_history \
    -v $input_dir:/home/accel-align-rmi/genomes \
    -it docker-align