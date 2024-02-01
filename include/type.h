#pragma once

#include "const.h"
#include "minimap.h"
#include "rmi.h"

struct Alignment {
  std::string cigar_string;
  int ref_begin;
  int mismatches;
};

struct Interval {
  uint32_t s, e;  // start, end position of the reference match to the whole read
};

struct Region {
  uint32_t rs, re;  // start, end position of the reference match to the whole read
  uint32_t qs, qe;  // start, end position of matched seed in the query (read)
  uint16_t cov;
  uint16_t embed_dist;
  int score;
  std::vector<Interval> matched_intervals;  // list of start pos of matched seeds in read that indicate to this region

  bool operator()(Region &X, Region &Y) {
    if (X.rs == Y.rs)
      return X.qs < Y.qs;
    else
      return X.rs < Y.rs;
  }
};

struct Read {
  char name[MAX_LEN], qua[MAX_LEN], seq[MAX_LEN], fwd[MAX_LEN], rev[MAX_LEN], rev_str[MAX_LEN], cigar[MAX_LEN];
  int tid, as, nm, best, secBest, best_optional, secBest_optional, ref_id, rlen;
  uint32_t pos;
  short mapq, kmer_step; //kmer_step used that find the seed
  char strand;
  Region best_region;

  char strand_optional;
  Region best_region_optional;

  bool force_align = false;

  friend gzFile &operator>>(gzFile &in, Read &r);

  Read() {
    best = INT_MAX;
    secBest = INT_MAX;
  }

};

class Reference {
 public:
  void load_index32(const char *F);   
  void load_index64(const char *F);   
  void load_index_classic(const char *F);
  std::function<void(const char*)> load_index;

  void index_lookup32(uint64_t key, size_t* b, size_t* e);
  void index_lookup64(uint64_t key, size_t* b, size_t* e);
  void index_lookup_classic(uint64_t key, size_t* b, size_t* e);
  std::function<void(uint64_t,size_t*,size_t*)> index_lookup;

  uint32_t get_keyv_val32(uint32_t idx);
  uint32_t get_keyv_val64(uint32_t idx);
  std::function<uint32_t(uint32_t)> get_keyv_val;

  void load_reference(const char *F);  // this is fine

  std::string ref;
  std::vector<std::string> name;
  std::vector<uint32_t> offset;
  uint32_t *keyv, *posv;              
  uint64_t nposv, nkeyv, nkeyv_true;
  mm_idx_t *mi;
  RMI rmi;  // this is fine
  unsigned kmer_len;
  bool enable_minimizer, enable_rmi;
  char mode; // 'c' c-> t; 'g' g->a; ' ' original

  Reference(const char *F, unsigned _kmer_len, bool _enable_minimizer, bool _enable_rmi, char mode);

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

// add RMI class 

// function typedefs
typedef bool (*load_type)(char const*);
typedef uint64_t (*lookup_type)(uint64_t, size_t*);
typedef void (*cleanup_type)();