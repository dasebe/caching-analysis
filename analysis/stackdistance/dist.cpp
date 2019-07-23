#include <fstream>
#include <iostream>
#include <string>
#include <regex>
#include "lru_variants.h"

using namespace std;

int main (int argc, char* argv[])
{

  // output help if insufficient params
  if(argc < 3) {
      cerr << argv[0] << " traceFile maxLength" << endl;
    return 1;
  }
  const char* path = argv[1];
  const uint64_t cache_size  = std::stoull(argv[3]);

  LRUCache list(cache_size);

  ifstream infile;
  long long reqs = 0, hits = 0;
  long long t, id, size;

  cerr << "running..." << endl;

  infile.open(path);
  while (infile >> t >> id >> size)
    {
        reqs++;
        
        if(list.lookup(id)) {
            hits++;
        } else {
            list.admit(id);
        }
    }

  infile.close();
  cout << " " << cache_size << " " << " " << " "
       << reqs << " " << hits << " "
       << double(hits)/reqs << endl;

  return 0;
}
