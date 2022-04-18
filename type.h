#pragma once

#include "const.h"

struct Alignment {
  std::string cigar_string;
  int ref_begin;
  int mismatches;
};

struct Interval {
  uint32_t s, e;  // start, end position of the reference match to the whole read
};

struct Region {
  uint64_t rs, re;  // start, end position of the reference match to the whole read
  uint32_t qs, qe;  // start, end position of matched seed in the query (read)
  uint16_t cov;
  uint16_t embed_dist;
  int score;
  std::vector<uint32_t> matched_intervals;  // list of start pos of matched seeds in read that indicate to this region

  bool operator()(Region &X, Region &Y) {
    if (X.rs == Y.rs)
      return X.qs < Y.qs;
    else
      return X.rs < Y.rs;
  }
};

struct Read {
  char name[MAX_LEN], qua[MAX_LEN], seq[MAX_LEN], fwd[MAX_LEN], rev[MAX_LEN], rev_str[MAX_LEN], cigar[MAX_LEN];
  int tid, as, nm, best, secBest;
  uint64_t pos;
  char strand;
  short mapq, kmer_len; //kmer_step used that find the seed
  Region best_region;

  friend gzFile &operator>>(gzFile &in, Read &r);

  Read() {
    best = INT_MAX;
    secBest = INT_MAX;
  }

};

class Reference {
 public:
  void load_index(const char *F);
  Reference(const char *F);

  std::string ref;
  std::vector<std::string> name;
  std::vector<uint64_t> offset;
  uint32_t nkeyv;

  uint64_t *keyv, *posv;
  uint64_t nposv;

  ~Reference();
};

typedef std::tuple<Read *, Read *, int> ReadCnt;

typedef std::tuple<Read *, Read *> ReadPair;

typedef struct {
  uint32_t capacity;
  uint32_t n_cigar;
  int32_t dp_score;
  uint32_t cigar[];
} Extension;