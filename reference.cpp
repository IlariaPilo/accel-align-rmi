#include "header.h"

extern uint8_t code[256];

class RefParser {
  string &ref;

 public:
  RefParser(string &ref) : ref(ref) {}

  void operator()(const tbb::blocked_range<size_t> &r) const {
    for (size_t i = r.begin(); i != r.end(); ++i)
      ref[i] = *(code + ref[i]);
  }
};

template <class T>
void Reference<T>::load_index(const char *F) {
  string fn = string(F) + ".hash";

  cerr << "loading hashtable from " << fn << endl;
  ifstream fi;
  fi.open(fn.c_str(), ios::binary);
  if (!fi) {
    cerr << "Unable to open index file " << fn << endl;
    exit(0);
  }
  fi.read((char *) &nposv, sizeof(T));
  fi.close();
  nkeyv = MOD + 1;

  cerr << "Mapping keyv of size: " << nkeyv * sizeof(T)<<
       " and posv of size " << (size_t) nposv * sizeof(T) <<
       " from index file " << fn << endl;
  cerr << "Mapping nkeyv : " << nkeyv <<
       " and nposv " << (size_t) nposv <<
       " from index file " << fn << endl;
  size_t posv_sz = (size_t) nposv * sizeof(T);
  size_t keyv_sz = (size_t) nkeyv * sizeof(T);
  int fd = open(fn.c_str(), O_RDONLY);

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

  char *base = reinterpret_cast<char *>(mmap(NULL, sizeof(T) + posv_sz + keyv_sz, PROT_READ, MMAP_FLAGS, fd, 0));
  assert(base != MAP_FAILED);
  posv = (T *)(base + sizeof(T));
  keyv = posv + nposv;
  cerr << "Mapping done" << endl;
  cerr << "done loading hashtable\n";
}

template <class T>
Reference<T>::Reference(const char *F) {
  auto start = std::chrono::system_clock::now();

  // Start index load in parallel
  thread t(&Reference::load_index, this, F);

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
        ref += buf;
        ref_size += buf.size();
      }
    }

    // process last chromosome
    cerr << "Parsing reference.\n";
    tbb::parallel_for(
        tbb::blocked_range<size_t>(0, ref_size),
        RefParser(ref));
    fi.close();
    offset.push_back(ref_size);
    cerr << "Loaded reference size: " << ref_size << endl;
  }

  // wait for index load to finish
  t.join();

  auto end = std::chrono::system_clock::now();
  auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
  cerr << "Setup reference in " << elapsed.count() / 1000000 << " secs\n";
}

template <class T>
Reference<T>::~Reference() {
  size_t posv_sz = (size_t) nposv * sizeof(T);
  size_t keyv_sz = (size_t) nkeyv * sizeof(T);
  char *base = (char *) posv - sizeof(T);
  int r = munmap(base, posv_sz + keyv_sz);
  assert(r == 0);
}


