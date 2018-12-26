#include <string>
#include <iostream>
#include <fstream>
#include <unordered_map>
#include <unordered_set>
#include <math.h>
using namespace std;

// main
int main(int argc, char* argv[])
{
  const char* path = argv[1];

  uint64_t t, id, size, hitsum = 0, reqsum = 0, sizesum = 0;
  long double util, dvar, hit;

    // I/O ifstream speed up trick
    setlocale(LC_ALL, "C");

  ifstream infile;
  infile.open(path);

  while (infile >> t >> id >> size >> util >> dvar >> hit)
    {
        if(hit>=0.9999999)
            hitsum++;
        reqsum++;
        sizesum += size;
    }
  
  cout << hitsum << " " << reqsum << " " << double(hitsum)/reqsum << " " << sizesum << '\n';

  return 0;
}
