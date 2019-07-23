#include <fstream>
#include <iostream>
#include <unordered_map>
#include <map>
#include "lru_variants.h"

using namespace std;

int main (int argc, char* argv[])
{

  // output help if insufficient params
  if(argc < 3) {
      cerr << argv[0] << " traceFile ignoreColumns" << endl;
    return 1;
  }
  const char* path = argv[1];
  const int ignore = stoi(argv[2]);

  ifstream infile;
  std::string t, id, tmp;

  LRUList list;
  long long reqs = 0;
  std::unordered_map<uint64_t, uint64_t> hist;

  cerr << "running..." << endl;

  infile.open(path);
  while (infile >> t >> id)
    {
        for(int i=0; i<ignore; i++) {
            infile >> tmp;
        }
        reqs++;
        hist[list.touch(id)]++;
    }

  infile.close();

  // hacky bucketed and sorted hist
  std::map<uint64_t, uint64_t> hist_sorted;
  for(auto & it: hist) {
    hist_sorted[(it.first / 10000)] += it.second;
  }
  for(auto & it: hist_sorted) {
      cout << it.first << " " << it.second << "\n";
  }

  return 0;
}
