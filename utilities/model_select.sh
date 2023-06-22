#!/bin/bash

read -ep $'\033[1;33m [index.sh] \033[0mwhich index would you like to train? [1-10] ' choice

choice=$((choice + 1))

read type branching size avg_err max_err b_time <<< $(sed -n "${choice}p" optimizer.out)
echo $type $branching $size $avg_err $max_err $b_time > rmi_type.txt