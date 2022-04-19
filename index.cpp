#include "header.h"

using namespace std;
const unsigned mod = (1UL << 29) - 1;

unsigned step = 1;
unsigned kmer;

template <typename T>
struct Data {
  uint32_t key;
  T pos;
  Data() : key(-1), pos(-1) {}
  Data(uint32_t k, T p) : key(k), pos(p) {}

  bool operator()(const Data &X, const Data &Y) const {
    return X.key == Y.key ? X.pos < Y.pos : X.key < Y.key;
  }

};

template <typename T>
class Index {
 private:
  string ref;
 public:
  bool load_ref(const char *F);
  bool make_index(const char *F);
  void cal_key(size_t i, vector<Data<T>> &data);
};

template <class T>
bool Index<T>::load_ref(const char *F) {
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

template <class T>
void Index<T>::cal_key(size_t i, vector<Data<T>> &data) {
  uint64_t h = 0;
  bool hasn = false;
  for (unsigned j = 0; j < kmer; j++) {
    if (ref[i + j] == 4) {
      hasn = true;
    }
    h = (h << 2) + ref[i + j];
  }
  if (!hasn && i % step == 0 ) {
    data[i / step].key = h % mod;
    data[i / step].pos = i;
  }
}

template <class T>
class Tbb_cal_key {
  vector<Data<T>> &data;
  Index<T> *index_obj;

 public:
  Tbb_cal_key(vector<Data<T>> &_data, Index<T> *_index_obj) :
      data(_data), index_obj(_index_obj) {}

  void operator()(const tbb::blocked_range<size_t> &r) const {
    for (size_t i = r.begin(); i != r.end(); ++i) {
      index_obj->cal_key(i, data);
    }
  }
};

template <class T>
bool Index<T>::make_index(const char *F) {
  size_t limit = ref.size() - kmer + 1;
  size_t vsz;
  if (step == 1)
    vsz = limit;
  else
    vsz = ref.size() / step + 1;

  vector<Data<T>> data(vsz, Data<T>());
  cerr << "hashing :limit = " << limit << ", vsz = " << vsz << endl;

  tbb::parallel_for(tbb::blocked_range<size_t>(0, limit), Tbb_cal_key<T>(data, this));
  cerr << "hash\t" << data.size() << endl;

  //XXX: Parallel sort uses lots of memory. Need to fix this. In general, we
  //use 8 bytes per item. Its a waste.
  try {
    cerr << "Attempting parallel sorting\n";
    tbb::task_scheduler_init init(tbb::task_scheduler_init::automatic);
    tbb::parallel_sort(data.begin(), data.end(), Data<T>());
  } catch (std::bad_alloc e) {
    cerr << "Fall back to serial sorting (low mem)\n";
    sort(data.begin(), data.end(), Data<T>());
  }

  cerr << "writing\n";
  string fn = F;
  fn += ".hash";
  ofstream fo(fn.c_str(), ios::binary);

  // determine the number of valid entries based on first junk entry
  auto joff = std::lower_bound(data.begin(), data.end(), Data<T>(-1, -1), Data<T>());
  size_t eof = joff - data.begin();
  cerr << "Found " << eof << " valid entries out of " <<
       data.size() << " total\n";
  fo.write((char *) &eof, sizeof(T));

  // write out keys
  for (size_t i = eof; i < data.size(); i++)
    assert(data[i].key == (uint32_t) -1);
  try {
    cerr << "Fast writing posv (" << eof << ")\n";
    T *buf = new T[eof];
    for (size_t i = 0; i < eof; i++) {
      buf[i] = data[i].pos;
    }
    fo.write((char *) buf, eof * sizeof(T));
    delete[] buf;
  } catch (std::bad_alloc e) {
    cerr << "Fall back to slow writing posv due to low mem.\n";
    for (size_t i = 0; i < eof; i++) {
      fo.write((char *) &data[i].pos, sizeof(T));
    }
  }

  size_t last_key = 0, offset;
  try {
    cerr << "Fast writing keyv\n";
    size_t buf_idx = 0;
    T *buf = new T[mod + 1];
    for (size_t i = 0; i < eof;) {
      assert (data[i].key != (uint32_t) -1);
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
    for (size_t j = last_key; j <= mod; j++) {
      buf[buf_idx] = offset;
      ++buf_idx;
    }
    assert(buf_idx == (mod + 1));
    fo.write((char *) buf, buf_idx * sizeof(T));
    delete[] buf;
  } catch (std::bad_alloc e) {
    cerr << "Fall back to slow writing keyv (low mem)\n";
    for (size_t i = 0; i < eof;) {
      assert (data[i].key != (uint32_t) -1);
      size_t h = data[i].key, n;
      offset = i;
      for (size_t j = last_key; j <= h; j++) {
        fo.write((char *) &offset, sizeof(T));
      }
      last_key = h + 1;
      for (n = i + 1; n < eof && data[n].key == h; n++);
      i = n;
    }
    offset = eof;
    for (size_t j = last_key; j <= mod; j++) {
      fo.write((char *) &offset, sizeof(T));
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
    cerr << "\t-s INT step of seed [1]\n";
    cerr << "\t-L Using the mode for large genome if longer than 4.2 billion nt";
    return 0;
  }
  unsigned kmer_temp = 0;
  bool large_genome = false;
  for (int it = 1; it < ac; it++) {
    if (strcmp(av[it], "-l") == 0)
      kmer_temp = atoi(av[it + 1]);
    else if (strcmp(av[it], "-s") == 0)
      step = atoi(av[it + 1]);
    else if (strcmp(av[it], "-L") == 0)
      large_genome = true;
  }
  kmer = 32;
  if (kmer_temp != 0)
    kmer = kmer_temp;

  cerr << "Using kmer length " << kmer << " and step size " << step << endl;

  if (large_genome){
    cout << "Using the mode for large genome (longer than 4.2 billion nt)" << endl;

    Index<uint64_t> i;
    if (!i.load_ref(av[ac - 1]))
      return 0;
    if (!i.make_index(av[ac - 1]))
      return 0;
  } else{
    cout << "Using the mode for normal genome (shorter than 4.2 billion nt)" << endl;

    Index<uint32_t> i;
    if (!i.load_ref(av[ac - 1]))
      return 0;
    if (!i.make_index(av[ac - 1]))
      return 0;
  }

  return 0;
}
