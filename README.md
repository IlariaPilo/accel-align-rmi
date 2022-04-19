## Overview ##

Accel-align is a fast alignment tool implemented in C++ programming language.

## Get started ##

### Docker Container ###

You can now pull a preconfigured docker container to get the binaries:

```
docker run -it rajaappuswamy/accel-align
```

### Pre-built binaries ###
Pre-built binaries with static linked lib in the repository: accalign-x86-64, accindex-x86-64.


### Pre-requirement ###

If you prefer to build by yourself, please download and install Intel TBB first.

#### Intel TBB ####

- source: https://github.com/01org/tbb/releases/tag/2019_U5
- libtbb-dev package

### Installation ###

* clone (git clone --recursive https://github.com/raja-appuswamy/accel-align-release)
* Build it: `make`

### Build index ###

It's mandatory to build the index before alignment. 
If the genome length is shorter than 4.2 billion nt (the size of uint32_t), the maximum memory needed to index is 32GB. 
Otherwise, please use the option '-L' to support large genome and that would need at least 64GB RAM. 
If you would like to align large genome with 32GB RAM only, please specify the option '-s 2' which would keep only one kmer of each two adjacent kmers in the index to reduce the memory requirement. 
Note: the same option used in index should be used in the alignment as well.   

Options:
```
-l INT the length of k-mers [32]
-s INT step of seed [1]
-L Using the mode for large genome if longer than 4.2 billion nt. It supports at most 4.2 billion nt (the size of uint32_t) defaultly. 
```

Example:

```
path-to-accel-align/accindex -l 32 path-to-ref/ref.fna
```

It will generate the index aside the reference genome as `path-to-ref/ref.fna.hash`.

### Align ###

When the alignment is triggered, the index will be loaded in memory automatically.

Options:

```
   -t INT number of cpu threads to use [1].
   -l INT length of seed [32].
   -s INT step of seed [1].
   -o name of output file to use.
   -x alignment-free.
   -w use WFA for extension. It's using KSW by default.
   -p the maximum distance allowed between the paired-end reads [1000].
   -d disable embedding, extend all candidates from seeding (this mode is super slow, only for benchmark).
   -L Using the mode for large genome if longer than 4.2 billion nt. It supports at most 4.2 billion nt (the size of uint32_t) defaultly. 
   Note: maximum read length and read name length supported are 512.
```

### Pair-end alignment ###

``` 
path-to-accel-align/accalign options ref.fna read1.fastq read2.fastq
```

Example:

``` 
path-to-accel-align/accalign -l 32 -t 4 -o output-path/out.sam \
path-to-ref/ref.fna input-path/read1.fastq input-path/read2.fastq
``` 

### Single-end alignment ###

``` 
path-to-accel-align/accalign options ref.fna read.fastq
```

Example:

``` 
path-to-accel-align/accalign -l 32 -t 4 -o output-path/out.sam \
path-to-ref/ref.fna input-path/read.fastq
``` 

### Alignment-free  mode ###

Accel-Align does base-to-base align by default. However, Accel-Align supports alignment-free mapping mode where the
position is reported without the CIGAR string.
`-x` option will enable the alignment-free mode.

Example:

``` 
path-to-accel-align/accalign -l 32 -t 4 -x -o output-path/out.sam \
path-to-ref/ref.fna input-path/read.fastq
``` 

### Citing Accel-align ###
If you use Accel-align in your work, please cite https://doi.org/10.1186/s12859-021-04162-z :

> Yan, Y., Chaturvedi, N. & Appuswamy, R. 
> Accel-Align: a fast sequence mapper and aligner based on the seed–embed–extend method. 
> BMC Bioinformatics 22, 257 (2021).
