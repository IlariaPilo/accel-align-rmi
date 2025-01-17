#include "header.h"

using namespace std;
uint64_t mod = MOD_29;    // default value is 2^29 - 1
uint32_t mod_tmp;
const unsigned step = 1;
uint32_t xxh_type = 0;
XXHash xxh;
unsigned kmer;
bool enable_idx_minimizer = false, enable_bs = false; //short for bisulfite reads

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
  bool load_ref(const char *F, char mode);
  bool make_index(const char *F, int id);
  void cal_key(size_t i, vector<Data> &data);
};

bool Index::load_ref(const char *F, char mode) {
  char code[256], buf[65536];
  for (size_t i = 0; i < 256; i++)
    code[i] = 4;
  code['A'] = code['a'] = 0;
  code['C'] = code['c'] = 1;
  code['G'] = code['g'] = 2;
  code['T'] = code['t'] = 3;

  if (mode == 'c')
    code['C'] = code['c'] = 3;
  else if (mode == 'g')
    code['G'] = code['g'] = 0;

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
    data[i / step].key = uint32_t(xxh(&h) % mod);
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

bool Index::make_index(const char *F, int id) {
  size_t limit = ref.size() - kmer + 1;
  size_t vsz;
  if (step == 1)
    vsz = limit;
  else
    vsz = ref.size() / step + 1;

  vector<Data> data(vsz, Data());
  cerr << "hashing : limit = " << limit << ", vsz = " << vsz << endl;
  cerr << "using MOD = " << mod << " and XXH = " << xxh_type << endl;

  tbb::parallel_for(tbb::blocked_range<size_t>(0, limit), Tbb_cal_key(data, this));
  cerr << "hash\t" << data.size() << endl;

  //XXX: Parallel sort uses lots of memory. Need to fix this. In general, we
  //use 8 bytes per item. Its a waste.
  try {
    cerr << "Attempting parallel sorting\n";
    tbb::task_scheduler_init init(tbb::task_scheduler_init::automatic);
    tbb::parallel_sort(data.begin(), data.end(), Data());
  } catch (std::bad_alloc &e) {
    cerr << "Fall back to serial sorting (low mem)\n";
    sort(data.begin(), data.end(), Data());
  }

  cerr << "writing\n";
  string fn = F;
  if (id)
    fn += ".hash"+to_string(kmer)+".part" + to_string(id);
  else
    fn += ".hash" + to_string(kmer);
  ofstream fo(fn.c_str(), ios::binary);

  // determine the number of valid entries based on first junk entry
  auto joff = std::lower_bound(data.begin(), data.end(), Data(-1, -1), Data());
  size_t eof = joff - data.begin();
  cerr << "Found " << eof << " valid entries out of " <<
       data.size() << " total\n";
  // first, write mod
  fo.write((char *) &mod, 4);
  // then, write xxh_type
  fo.write((char *) &xxh_type, 4);
  // then, write the number of positions
  fo.write((char *) &eof, 4);

  // write out positions
  for (size_t i = eof; i < data.size(); i++)
    assert(data[i].key == (uint32_t) -1);
  try {
    cerr << "Fast writing posv (" << eof << ")\n";
    uint32_t *buf = new uint32_t[eof];
    for (size_t i = 0; i < eof; i++) {
      buf[i] = data[i].pos;
    }
    fo.write((char *) buf, eof * sizeof(uint32_t));
    delete[] buf;
  } catch (std::bad_alloc &e) {
    cerr << "Fall back to slow writing posv due to low mem.\n";
    for (size_t i = 0; i < eof; i++) {
      fo.write((char *) &data[i].pos, 4);
    }
  }

  // write out keys
  size_t last_key = 0, offset;
  try {
    cerr << "Fast writing keyv\n";
    uint64_t buf_idx = 0;
    uint32_t *buf = new uint32_t[mod + 1];
    // for each position
    for (size_t i = 0; i < eof;) {
      assert (data[i].pos != (uint32_t) -1);
      size_t h = data[i].key, n;
      offset = i;
      for (size_t j = last_key; j <= h; j++) {
        buf[buf_idx] = offset;
        ++buf_idx;
      }
      last_key = h + 1;
      for (n = i + 1; n < eof && data[n].key == h; n++);
      i = n;
    }
    offset = eof;
    for (uint64_t j = (uint64_t)last_key; j <= mod; j++) {
      buf[buf_idx] = offset;
      ++buf_idx;
    }
    assert(buf_idx == (mod + 1));
    fo.write((char *) buf, buf_idx * sizeof(uint32_t));
    delete[] buf;
  } catch (std::bad_alloc &e) {
    cerr << "Fall back to slow writing keyv (low mem)\n";
    for (size_t i = 0; i < eof;) {
      assert (data[i].pos != (uint32_t) -1);
      size_t h = data[i].key, n;
      offset = i;
      for (size_t j = last_key; j <= h; j++) {
        fo.write((char *) &offset, 4);
      }
      last_key = h + 1;
      for (n = i + 1; n < eof && data[n].key == h; n++);
      i = n;
    }
    offset = eof;
    for (uint64_t j = (uint64_t)last_key; j <= mod; j++) {
      fo.write((char *) &offset, 4);
    }
  }

  cerr << "Indexing complete\n";
  fo.close();
  return true;
}

int main(int ac, char **av) {
  if (ac < 2) {
    cerr << "index [options] <ref.fa>\n";
    cerr << "options:\n";
    cerr << "\t-l INT length of seed [32]\n";
    cerr << "\t-h INT value of hash MOD [2^29-1]\n";
    cerr << "\t   Special string values = 2^29-1, 2^32, prime, lprime\n";
    cerr << "\t-x INT size of xxhash [0]\n";
    cerr << "\t   Values = 0 (xxh not used), 32, 64\n";
    cerr << "\t-m enable minimizer\n";
    cerr << "\t-k minimizer: k, kmer size \n";
    cerr << "\t-w minimizer: w, window size \n";
    cerr << "\t-s bisulfite sequencing read alignment mode \n";
    return 0;
  }

  unsigned kmer_temp = 0, mm_k_tmp = 0, mm_w_tmp = 0;

  for (int it = 1; it < ac; it++) {
    if (strcmp(av[it], "-l") == 0)
      kmer_temp = atoi(av[it + 1]);
    else if (strcmp(av[it], "-m") == 0)
      enable_idx_minimizer = true;
    else if (strcmp(av[it], "-k") == 0)
      mm_k_tmp = atoi(av[it + 1]);
    else if (strcmp(av[it], "-w") == 0)
      mm_w_tmp = atoi(av[it + 1]);
    else if (strcmp(av[it], "-s") == 0)
      enable_bs = true;
    else if (strcmp(av[it], "-h") == 0) {
      // check for special string values
      if (strcmp(av[it+1], "2^29") == 0 || strcmp(av[it+1], "2^29-1") == 0)
        mod = MOD_29;
      else if (strcmp(av[it+1], "2^32") == 0)
        mod = MOD_32;
      else if (strcmp(av[it+1], "prime") == 0)
        mod = MOD_PRIME;
      else if (strcmp(av[it+1], "lprime") == 0)
        mod = MOD_LPRIME;
      // now do classic conversion
      else try {
        mod_tmp = stoul(string(av[it+1]));
        mod = static_cast<uint64_t>(mod_tmp);
        } catch (const invalid_argument& e) {
            cerr << "Invalid argument: " << e.what() << endl;
            cerr << "Special string values for -h are 2^29-1, prime, lprime.\n";
            exit(1);
        } catch (const out_of_range& e) {
            cerr << "Out of range: " << e.what() << endl;
            exit(1);
        }
    } 
    else if (strcmp(av[it], "-x") == 0) {
      xxh_type = atoi(av[it + 1]);
      if (xxh_type!=0 && xxh_type!=32 && xxh_type!=64) {
        cerr << "Unknown value for xxhash. \nSupported values: 0 (xxh not used), 32, 64.\n";
        exit(1);
      }
    }
  }
  string fn = av[ac - 1]; //input ref file name
  bind_xxhash(xxh_type, xxh);

  if (enable_idx_minimizer) {
    int n_threads = 3;
    mm_idxopt_t ipt;
    mm_idxopt_init(&ipt);
    if (mm_k_tmp)
      ipt.k = mm_k_tmp;
    if (mm_w_tmp)
      ipt.w = mm_w_tmp;

    fn += ".hash"; // output hash: xxx.hash

    mm_idx_reader_t *idx_rdr = mm_idx_reader_open(av[ac - 1], &ipt, fn.c_str());
    mm_idx_reader_read(idx_rdr, n_threads);
  } else if (enable_bs) {
    kmer = kmer_temp ? kmer_temp: 32;
    cerr << "Using kmer length " << kmer << " and step size " << step << endl;

    cerr << "==== convert reference C to T ===="  << endl;
    Index ic;
    if (!ic.load_ref(fn.c_str(), 'c'))
      return 0;
    if (!ic.make_index(fn.c_str(), 1))
      return 0;

    cerr << "==== convert reference G to A ===="  << endl;
    Index ig;
    if (!ig.load_ref(fn.c_str(), 'g'))
      return 0;
    if (!ig.make_index(fn.c_str(), 2))
      return 0;

    cerr << "hash1 and hash2 have been generated"  << endl;
  } else {
    kmer = kmer_temp ? kmer_temp: 32;

    cerr << "Using kmer length " << kmer << " and step size " << step << endl;

    Index i;
    if (!i.load_ref(fn.c_str(), ' '))
      return 0;
    if (!i.make_index(fn.c_str(), 0))
      return 0;
  }

  return 0;
}
