#include "header.h"

using namespace std;
const unsigned mod = (1UL << 29) - 1;
const unsigned step = 1;
unsigned kmer;

// a structure of pairs (key, position)
struct Data {
  uint32_t key, pos;
  Data() : key(-1), pos(-1) {}
  Data(uint32_t k, uint32_t p) : key(k), pos(p) {}

  bool operator()(const Data &X, const Data &Y) const {
    return X.key == Y.key ? X.pos < Y.pos : X.key < Y.key;
  }

};

class Index {
 private:
  string ref;
 public:
  bool load_ref(const char *F);
  bool key_gen();
  void cal_key(size_t i, vector<Data> &data);
};

// function to load the reference string
// each nucleotide basis is mapped to a 8-bit value
// A -> 0
// C -> 1
// G -> 2
// T -> 3
// else (N) -> 4
bool Index::load_ref(const char *F) {
  char code[256], buf[65536];
  for (size_t i = 0; i < 256; i++)
    code[i] = 4;
  code['A'] = code['a'] = 0;
  code['C'] = code['c'] = 1;
  code['G'] = code['g'] = 2;
  code['T'] = code['t'] = 3;
  cerr << "Loading ref\n";
  FILE *f = fopen(F, "rb");
  if (f == NULL)
    return false;
  fseek(f, 0, SEEK_END);
  ref.reserve(ftell(f) + 1);
  fclose(f);
  f = fopen(F, "rt");
  if (f == NULL)
    return false;
  while (fgets(buf, 65536, f) != NULL) {
    if (buf[0] == '>')
      continue;
    for (char *p = buf; *p; p++)
      if (*p >= 33)
        ref.push_back(*(code + *p));
  }
  fclose(f);
  cerr << "genome\t" << ref.size() << '\n';
  return true;
}

// compute the key value by using 2 bits for each basis (N is discarded)
// Example: ACCT -> 00-01-01-11
void Index::cal_key(size_t i, vector<Data> &data) {
  uint64_t h = 0;
  bool hasn = false;
  for (unsigned j = 0; j < kmer; j++) {
    if (ref[i + j] == 4) {
      hasn = true;
    }
    h = (h << 2) + ref[i + j];
  }
  if (!hasn) {
    data[i / step].key = h % mod;
    data[i / step].pos = i;
  }
}

class Tbb_cal_key {
  vector<Data> &data;
  Index *index_obj;

 public:
  Tbb_cal_key(vector<Data> &_data, Index *_index_obj) :
      data(_data), index_obj(_index_obj) {}

  void operator()(const tbb::blocked_range<size_t> &r) const {
    for (size_t i = r.begin(); i != r.end(); ++i) {
      index_obj->cal_key(i, data);
    }
  }
};

// TODO - save positions somewhere (up to now, only keys)
bool Index::key_gen() {
  size_t limit = ref.size() - kmer + 1;
  size_t vsz;
  if (step == 1)
    vsz = limit;
  else
    vsz = ref.size() / step + 1;

  vector<Data> data(vsz, Data());
  cerr << "hashing :limit = " << limit << ", vsz = " << vsz << endl;

  // get the hash for each key
  tbb::parallel_for(tbb::blocked_range<size_t>(0, limit), Tbb_cal_key(data, this));
  cerr << "hash\t" << data.size() << endl;

  // sort keys
  //XXX: Parallel sort uses lots of memory. Need to fix this. In general, we
  //use 8 bytes per item. Its a waste.
  try {
    cerr << "Attempting parallel sorting\n";
    tbb::parallel_sort(data.begin(), data.end(), Data());
  } catch (std::bad_alloc& e) {
    cerr << "Fall back to serial sorting (low mem)\n";
    sort(data.begin(), data.end(), Data());
  }
  
  string fn = "keys_uint32";

  ofstream fo_key(fn.c_str(), ios::binary);

  // determine the number of valid and unique entries
  uint32_t prec = (uint32_t) -1;
  uint64_t eof = 0;
  uint32_t same;
  size_t valid;   // the number of entries different than -1

  size_t i;

  for (i = 0; i < data.size() && data[i].key != (uint32_t) -1; i++) {
    if (data[i].key != prec) {
        prec = data[i].key;
        eof ++;
      }
  }
  valid = i;
  cerr << "Found " << eof << " valid keys and " << valid << " valid positions out of " <<
       data.size() << " total\n\n";
  // The number of entries is required to be a 64-bit value
  fo_key.write((char *) &eof, 8);

  // write out keys
  try {
    cerr << "Fast writing keys (" << eof << ")\n";
    uint32_t *buf = new uint32_t[eof*2];
    // the previous value
    prec = data[0].key; 
    // the number of previous values which where the same
    same = 0;
    size_t i_buf;

    for (i = 0, i_buf = 0; i < valid; i++) {
      if (data[i].key != prec) {
        buf[i_buf++] = prec;
        buf[i_buf++] = same;
        prec = data[i].key;
        same = 0;
      }
      same++;
    }
    // add the last one
    buf[i_buf++] = prec;
    buf[i_buf] = same;
    fo_key.write((char *) buf, eof*2 * sizeof(uint32_t));
    delete[] buf;

  } catch (std::bad_alloc& e) {
    cerr << "Fall back to slow writing keys due to low mem.\n";
    // the previous value
    prec = data[0].key;
    // the number of previous values which where the same
    same = 0;
    uint32_t buf[2];

    for (size_t i = 0; i < valid; i++) {
      if (data[i].key != prec) {
        buf[0] = prec;
        buf[1] = same;
        fo_key.write((char *) buf, 8);
        prec = data[i].key;
        same = 0;
      }
      same++;
    }
    // add the last one
    buf[0] = prec;
    buf[1] = same;
    fo_key.write((char *) buf, 8);
  }
  cerr << "Key generation complete!\n\n";
  fo_key.close();

  // now, write positions
  fn = "pos_uint32";

  ofstream fo_pos(fn.c_str(), ios::binary);

  eof = (uint64_t) valid;
  fo_pos.write((char *) &eof, 8);

  try {
    cerr << "Fast writing posv (" << eof << ")\n";
    uint32_t *buf = new uint32_t[eof];
    for (i = 0; i < eof; i++) {
      buf[i] = data[i].pos;
    }
    fo_pos.write((char *) buf, eof * sizeof(uint32_t));
    delete[] buf;
  } catch (std::bad_alloc& e) {
    cerr << "Fall back to slow writing posv due to low mem.\n";
    for (i = 0; i < eof; i++) {
      fo_pos.write((char *) &data[i].pos, 4);
    }
  }

  cerr << "Position generation complete!\n\n";
  fo_pos.close();

  return true;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    cerr << "key_gen <ref.fna>\n";
    return 0;
  }
  unsigned kmer_temp = 0;
  for (int it = 1; it < argc; it++) {
    if (strcmp(argv[it], "-l") == 0)
      kmer_temp = atoi(argv[it + 1]);
  }
  kmer = 32;
  if (kmer_temp != 0)
    kmer = kmer_temp;

  cerr << "Using kmer length " << kmer << " and step size " << step << endl;

  Index i;
  if (!i.load_ref(argv[argc - 1]))
    return 0;
  if (!i.key_gen())
    return 0;
  return 0;
}
