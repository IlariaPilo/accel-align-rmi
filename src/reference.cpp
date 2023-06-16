#include "header.h"

class RefParser {
  string &ref;
  char mode;

 public:
  RefParser(string &_ref, char _mode) : ref(_ref), mode(_mode) {}

  void operator()(const tbb::blocked_range<size_t> &r) const {
    uint8_t code[256];
    for (size_t i = 0; i < 256; i++)
      code[i] = 4;

    code['A'] = code['a'] = 0;
    code['C'] = code['c'] = 1;
    code['G'] = code['g'] = 2;
    code['T'] = code['t'] = 3;
    code['N'] = code['n'] = 0;

    if (mode == 'c')
      code['C'] = code['c'] = 3;
    else if (mode == 'g')
      code['G'] = code['g'] = 0;

    for (size_t i = r.begin(); i != r.end(); ++i)
      ref[i] = *(code + ref[i]);
  }
};

// F should be the directory, that is <reference_prefix>_index
void Reference::load_index(const char *F) {

  string keys_f = string(F) + "/keys_uint32";
  string pos_f = string(F) + "/pos_uint32";
  //string fn;
  //if (mode == ' ') {
  //  fn = string(F) + ".hash";
  //}
  // ignore this ones
  //else if (mode == 'c')
  //  fn = string(F) + ".hash.part1";
  //else if (mode == 'g')
  //  fn = string(F) + ".hash.part2";

  ifstream fi;
  fi.open(keys_f.c_str(), ios::binary);
  if (!fi) {
    cerr << "Unable to open key file" << endl;
    exit(0);
  }
  fi.read((char *) &nkeyv, 4);
  nkeyv *= 2;
  fi.close();
  //nkeyv = MOD + 1;

  fi.open(pos_f.c_str(), ios::binary);
  if (!fi) {
    cerr << "Unable to open pos file" << endl;
    exit(0);
  }
  fi.read((char *) &nposv, 4);
  fi.close();

  cerr << "Mapping keyv of size: " << nkeyv * 4 <<
       " and posv of size " << (size_t) nposv * 4 << endl;
  size_t posv_sz = (size_t) nposv * sizeof(uint32_t);
  size_t keyv_sz = (size_t) nkeyv * sizeof(uint32_t);

#if __linux__
#include <linux/version.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
#define _MAP_POPULATE_AVAILABLE
#endif
#endif

#ifdef _MAP_POPULATE_AVAILABLE
#define MMAP_FLAGS (MAP_PRIVATE | MAP_POPULATE)
#else
#define MMAP_FLAGS MAP_PRIVATE
#endif

  int fd = open(keys_f.c_str(), O_RDONLY);
  char *base = reinterpret_cast<char *>(mmap(NULL, 4 + keyv_sz, PROT_READ, MMAP_FLAGS, fd, 0));
  assert(base != MAP_FAILED);
  keyv = (uint32_t * )(base + 4);

  fd = open(pos_f.c_str(), O_RDONLY);
  base = reinterpret_cast<char *>(mmap(NULL, 4 + posv_sz, PROT_READ, MMAP_FLAGS, fd, 0));
  assert(base != MAP_FAILED);
  posv = (uint32_t * )(base + 4);

  cerr << "Mapping done" << endl;
  cerr << "done loading hashtable\n";
}

void Reference::load_reference(const char *F){
  size_t ref_size = 0;
  string bref(F);
  bref += ".bref";
  ifstream brefin(bref.c_str(), ios::in);
  if (brefin) {
    /* Experimentation revealed that using prebuild binary ref leads to
     * embeding procedure taking more latency on memory stalls. Might have
     * something to do with ref now being loaded in cache. So while support
     * is there so that we can test it on other servers, it is disabled.
     */
    cout << "WARNING: USING PREBUILD BINARY REF.\n";
    cout << "-----------------------------------\n";
    cout << "Loading index and binary ref from " << bref << endl;
    size_t count;
    brefin >> count;
    cout << "Done loading " << count << " names " << endl;
    for (size_t i = 0; i < count; ++i) {
      string tmp;
      brefin >> tmp;
      name.push_back(tmp);
    }
    brefin >> count;
    for (size_t i = 0; i < count; ++i) {
      uint32_t tmp;
      brefin >> tmp;
      offset.push_back(tmp);
    }
    cout << "Done loading " << count << " offsets " << endl;
    brefin >> ref_size;
    ref.resize(ref_size);
    brefin.read(&ref[0], ref_size);
    cout << "Done loading binary ref of sz " << ref_size << endl;
    brefin.close();
  } else {
    FILE *f = fopen(F, "rb");
    fseek(f, 0, SEEK_END);
    ref.reserve(ftell(f) + 1);
    ref = "";
    fclose(f);

    ifstream fi(F);
    if (!fi) {
      cerr << "fail to open " << F << '\n';
      return;
    }
    cerr << "loading references\n";
    string buf = "";
    while (!fi.eof()) {
      getline(fi, buf);
      if (!buf.size())
        continue;

      if (buf[0] == '>') {
        string tmp(buf.c_str() + 1);
        istringstream iss(tmp);
        vector<string> parsed((istream_iterator<string>(iss)),
                              istream_iterator<string>());
        //cerr<<"Loading chromosome " << parsed[0] << "\n";
        name.push_back(parsed[0]);
        offset.push_back(ref_size);
      } else {
        if (isspace(buf[buf.size()-1])) { // isspace(): \t, \n, \v, \f, \r
          ref += buf.substr(0, buf.size()-1);
          ref_size += buf.size() - 1;
        } else {
          ref += buf;
          ref_size += buf.size();
        }
      }
    }

    // process last chromosome
    cerr << "Parsing reference.\n";
    tbb::parallel_for(
        tbb::blocked_range<size_t>(0, ref_size),
        RefParser(ref, mode));
    fi.close();
    offset.push_back(ref_size);
    cerr << "Loaded reference size: " << ref_size << endl;
  }
}

// add lookup function
/**
 * Function to query the RMI index.
 *
 * It first uses the rmi::lookup function and then performs a binary search, bounded by the (known) error.
 *
 * @param key The value we want to search in the index.
 * @return The position of key in the index container, UINT32_T(-1) if the key was not found.
 */
uint32_t Reference::index_lookup(uint32_t key) {
  size_t err;
  uint32_t guess_key, guess_pos;
  uint32_t l, r;
  uint64_t key64 = (uint64_t) key;
  // call the lookup function of the index
  guess_pos = (uint32_t) rmi.lookup(key64, &err)*2;
  // set up l and r for the bounded binary search
  l = std::max(int32_t(0), static_cast<int32_t>(guess_pos-err*2));
  r = std::min(static_cast<int32_t>(guess_pos+err*2), static_cast<int32_t>(nkeyv-1));
  // check in the keyv array
  while (l <= r) {
      guess_key = keyv[guess_pos];
      // if it's the same, done
      if (guess_key == key)
          return guess_pos;
      // else, do binary search
      if (guess_key < key) {
          l = guess_pos + 2;
      } else {
          r = guess_pos - 2;
      }
      // update guess_pos
      guess_pos = l + (r-l)/2;
  }
  // not found :(
  return -1;
}

Reference::Reference(const char *F, bool _enable_minimizer, char _mode): enable_minimizer(_enable_minimizer), mode(_mode){
  auto start = std::chrono::system_clock::now();

  if (enable_minimizer){
    int n_threads = 3;

    mm_idxopt_t ipt;
    mm_idxopt_init(&ipt);
    string fn = string(F) + ".hash";
    const char* fnw = fn.c_str();

    mm_idx_reader_t *idx_rdr = mm_idx_reader_open(fnw, &ipt, nullptr);
    mi = mm_idx_reader_read(idx_rdr, n_threads);

    load_reference(F);
  } else{
    string F_index = string(F).substr(0, string(F).find_last_of(".")) + "_index";
    thread t(&Reference::load_index, this, F_index.c_str()); // load index in parallel

    load_reference(F);    // TODO - why?

    t.join(); // wait for index load to finish
  }

  auto end = std::chrono::system_clock::now();
  auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
  cerr << "Setup reference in " << elapsed.count() / 1000000 << " secs\n";
}

Reference::~Reference() {
  if (enable_minimizer){
    mm_idx_destroy(mi);
  } else {
    size_t posv_sz = (size_t) nposv * sizeof(uint32_t);
    size_t keyv_sz = (size_t) nkeyv * sizeof(uint32_t);
    char *base = (char *) keyv - 4;
    int r = munmap(base, keyv_sz + 4);  // TODO - +4 was not present at the beginning
    assert(r == 0);

    base = (char *) posv - 4;
    r = munmap(base, posv_sz + 4);  // TODO - +4 was not present at the beginning
    assert(r == 0);
  }
}


