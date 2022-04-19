#pragma once

#include "const.h"

struct Alignment {
  std::string cigar_string;
  int ref_begin;
  int mismatches;
};

template <typename T>
struct array {
  size_t x;
  T *ary;
};

template <typename T>
struct Region{
  T rs, re;  // start, end position of the reference match to the whole read
  uint32_t qs, qe;  // start, end position of matched seed in the query (read)
  uint16_t cov;
  uint16_t embed_dist;
  int score;
  std::vector<uint32_t> matched_intervals;  // list of start pos of matched seeds in read that indicate to this region

  bool operator()(Region<T>&X, Region<T>&Y) {
    if (X.rs == Y.rs)
      return X.qs < Y.qs;
    else
      return X.rs < Y.rs;
  }
};

template <class T>
struct Read{
  char name[MAX_LEN], qua[MAX_LEN], seq[MAX_LEN], fwd[MAX_LEN], rev[MAX_LEN], rev_str[MAX_LEN], cigar[MAX_LEN];
  int tid, as, nm, best, secBest;
  T pos;
  char strand;
  short mapq, kmer_len; //kmer_step used that find the seed
  Region<T> best_region;

  friend gzFile &operator>>(gzFile &in, Read<T>&r){
      char temp[MAX_LEN];

      if (gzgets(in, r.name, MAX_LEN) == NULL)
        return in;
      if (gzgets(in, r.seq, MAX_LEN) == NULL)
        return in;
      if (gzgets(in, temp, MAX_LEN) == NULL)
        return in;
      if (gzgets(in, r.qua, MAX_LEN) == NULL)
        return in;

      unsigned i = 0;
      while (i < strlen(r.name)) {
        if (isspace(r.name[i])) { // isspace(): \t, \n, \v, \f, \r
          memset(r.name + i, '\0', strlen(r.name) - i);
          break;
        }
        i++;
      }

      r.qua[strlen(r.qua) - 1] = '\0';
      r.seq[strlen(r.seq) - 1] = '\0';

      r.tid = r.pos = 0;
      r.as = std::numeric_limits<int32_t>::min();
      r.strand = '*';

      return in;
  };


  Read() {
    best = INT_MAX;
    secBest = INT_MAX;
  }

};

template <class T>
class Reference {
 public:
  void load_index(const char *F);
  Reference(const char *F);

  std::string ref;
  std::vector<std::string> name;
  std::vector<T> offset;
  uint32_t nkeyv;

  T *keyv, *posv;
  T nposv;

  ~Reference();
};

typedef struct {
  uint32_t capacity;
  uint32_t n_cigar;
  int32_t dp_score;
  uint32_t cigar[];
} Extension;