#include <fstream>
#include <iostream>
#include <string>
#include <regex>
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

  LRUList list;

  ifstream infile;
  long long reqs = 0;
  std::string t, id, size;

  cerr << "running..." << endl;

  infile.open(path);
  while (infile >> t >> id >> size)
    {
        reqs++;

        cout << list.touch(id) << "\n";
    }

  infile.close();

  return 0;
}
