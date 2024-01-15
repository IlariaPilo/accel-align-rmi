# 🧬 accel-align-rmi

A version of [Accel-Align](https://github.com/raja-appuswamy/accel-align-release) using the RMI index.

**_See also the [original README](./README_og.md)._**

## 🐑 Clone the repository
The repository can be cloned by running:
```sh
git clone --recursive https://github.com/IlariaPilo/accel-align-rmi
```

## ⏬ Download a reference string【 optional 】
The script [`/data/download.sh`](./data/download.sh) can be used to download and post-process a reference string. The downloaded string is called `hg37.fna`, and it is saved in the current working directory.

## 🗺️ Configure the TBB path
Accel-Align-RMI requires [TBB](https://github.com/01org/tbb/releases/tag/2019_U5). After installing the library, it is necessary to modify the value of the `TBB_LIB` variable in the Makefile, setting it to the path of the shared object. Fox example:
```diff
- TBB_LIB =	## your path here ##
+ TBB_LIB = /usr/lib/x86_64-linux-gnu/libtbb.so
```

## 📚 Build the index
The learned index must be built offline, before running the aligner. This can be done by using the [`index.sh`](./index.sh) script:
```sh
bash index.sh [OPTIONS] <reference.fna>
```
The script supports the following options:
```
  -t, --threads  THREADS  The number of threads to be used. Default = all
  -l, --len      LEN      The length of the kmer. Default = 32
  -h, --help              Display this help message
```
It generates an output directory `<reference_string>_index<LEN>`, containing all index-related files, including:
- `keys_uintXX` and `pos_uint32` - two binary files storing keys and positions in the index, respectively. The first value in both files is a uint64 counter of the number of entries. Then, `keys_uintXX` contains pairs (uintXX key, uint32 cumulative_pos), where cumulative_pos is the sum of positions associated to a key lower than the current one. XX is equal to 32 if LEN <= 16 (meaning the kmer fits in 32 bits), to 64 otherwise. `pos_uint32` contains simply a list of uint32 positions.
- `optimizer.out` - the output of the RMI hyperparameter optimizer. It stores the 10 most promising architectures, as well as some statistics on their size and training time.
- `rmi_type.txt` - the architecture of the chosen RMI index.
- `<reference_string>_indexXX.so` and `<reference_string>_indexXX.sym` - the generated shared object for the index and the list of symbol names for the main functions. Notice that the list is necessary to avoid issues with different C++ standards.

## 🔎 Call the aligner
The aligner can be built with `make accalign`, and then run as:
```sh
./accalign [OPTIONS] <ref.fa> <read.fastq>
```
The following options are available:
```
  -t  INT   The number of threads to be used. Default = all
  -l  INT   The length of the kmer. Default = 32
  -o        Name of the output file
```
⚠️ The original Accel-Align allows more options, which are not yet supported in the RMI version.

## 🎯 Compute the index precision
An alignment run will possibly benefit of the RMI index if the classic index precision is low. This mean that the index is returning positions which are actually associated with wrong seeds. 

To better analyze this behavior, the script [`stats.sh`](./stats.sh) can be used.
```sh
bash stats.sh [OPTIONS] <reference.fna> <read.fastq>
```
The following options are available:
```
  -l, --len   LEN   The length of the kmer. Default = 32
  -h, --help        Display this help message
```
The script first generates the classic index `<reference.fna>.hash`, and then computes its precision (that is, the ratio between correct positions and returned positions) using as seeds kmers coming from the `<read.fastq>` file. Results are saved in a `<read.fastq>.stats<LEN>` csv file.

It also processes the csv file, and it plots a histogram and a pie chart using the [`stats_analyzer.py`](./utilities/stats_analyzer.py) script.

![Precision for the classical index on reference 'hg37.fna' and reads 'sv-10m-100-r.fastq' with size = 32](./data/readme_pic.png)

## 🛠️ Utility folder
The `utility` folder contains some useful helper scripts.

### benchmark_local.sh
This [script](./utilities/benchmark_local.sh) can be used to run automatic benchmarks comparing accel-align with/without learned index.
It should be moved from the `utility` directory into a parent directory containing both `accel-align-rmi` and `accel-align-release`. Programs should be already compiled.

Usage
```
    bash benchmark_local.sh <thread_number> [<number_of_executions>]
Runs some benchmarks for accel-align (with/without rmi index).
Executables should be already present (just run make).
Indices should be built in advance (with -l 16 option).
<thread_number> specifies the number of threads to be used.
<number_of_executions> is the number of times every program is called [default is 10]
```

### 🔬 binary_print.py
This [script](./utilities/binary_print.sh) can be used to display the content of `keys_uint32`, `keys_uint64` or `pos_uint32` binary files in a human-readable format.

```sh
python3 binary_print.py [OPTIONS] <filename>
```
It supports the following options:
```
  -n, --num_entries N   Number of entries to be displayed. Default = 10
  -b, --backward        Read backward. Default = off
  -f, --forward         Read forward. Default = on
  -h, --help            Show this help message and exit
```

### key_2_string.py
This [script](./utilities/key_2_string.py) takes a uint32 key and recovers the 16-char long kmer that generated it.

Usage
```
    python3 key_2_string.py <key>
Takes the key and converts it into a kmer, assuming its length is 16.
```

### search_key.py
This [script](./utilities/search_key.py) searches if a given key is present in a file. It is supposed to be used only on keys_uint32 files (that is, key files generated by index.sh).

Usage
```
    python search_key.py <filename> <key>
Search the key in <filename> file.
Passing 'min' as key returns the minimum, passing 'max' the maximum.
```

## 🐋 Docker folder
**_⚠️ The Docker folder functionality is currently broken, as the newest version of tbb is not compatible with accel-align :(_** 

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