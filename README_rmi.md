# accel-align-rmi

A version of [Accel-Align](https://github.com/raja-appuswamy/accel-align-release) using the RMI index.


## Clone
The repository can be cloned by running the following command:
```
git clone --recursive https://github.com/IlariaPilo/accel-align-rmi
```
## Docker module
To run the program inside a container, run the following commands:
```
cd docker
bash build.sh
bash run.sh <data_directory>
```
where _data_directory_ is the directory storing the reference string (and the results).

The generated credentials are (with `sudo` permissions):
```
USER: aligner
PASSWORD: password
```

## Download a reference string
The script `/data/download.sh` can be used to download and post-process a reference string. The donwloaded string is called `hg37.fna`, and it is saved in the current working directory.

## Build the index
The index can be built by simply running:
```
bash index.sh <reference_string.fna>
```