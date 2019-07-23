#include <fstream>
#include <iostream>
#include <unordered_map>
#include <map>
#include "lru_variants.h"

using namespace std;

int main (int argc, char* argv[])
{

  // output help if insufficient params
  if(argc < 2) {
      cerr << argv[0] << " traceFile" << endl;
    return 1;
  }
  const char* path = argv[1];

  ifstream infile;
  std::string t, id, size;

  LRUList list;
  long long reqs = 0;
  std::unordered_map<uint64_t, uint64_t> hist;

  cerr << "running..." << endl;

  infile.open(path);
  while (infile >> t >> id >> size)
    {
        reqs++;
        hist[list.touch(id)]++;
    }

  infile.close();

  // hacky sort on hist
  std::map<uint64_t, uint64_t> hist_sorted;
  for(auto & it: hist) {
      hist_sorted[it.first] = it.second;
  }
  for(auto & it: hist_sorted) {
      cout << it.first << " " << it.second << "\n";
  }

  return 0;
}
