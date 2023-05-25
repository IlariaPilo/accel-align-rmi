#!/bin/bash

# Check if the user has provided an argument
if [ $# -eq 0 ]; then
    input_dir="../data"
else
    input_dir=$1
fi

input_dir=$(realpath $input_dir)

echo "Using input directory $input_dir"

docker run --rm -v $input_dir:/home/aligner/accel-align-rmi/data \
    -it docker-align