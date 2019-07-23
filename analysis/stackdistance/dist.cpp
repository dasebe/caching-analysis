#include <fstream>
#include <iostream>
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
