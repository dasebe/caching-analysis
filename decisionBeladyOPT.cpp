#include <string>
#include <iostream>
#include <fstream>
#include <unordered_map>
#include <map>
#include <vector>
#include <math.h>
using namespace std;

// from boost hash combine: hashing of std::pairs for unordered_maps
template <class T>
inline void hash_combine(std::size_t & seed, const T & v)
{
  std::hash<T> hasher;
  seed ^= hasher(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}

namespace std
{
  template<typename S, typename T> struct hash<pair<S, T>>
  {
    inline size_t operator()(const pair<S, T> & v) const
    {
      size_t seed = 0;
      ::hash_combine(seed, v.first);
      ::hash_combine(seed, v.second);
      return seed;
    }
  };
}

// main
int main(int argc, char* argv[])
{
    // I/O ifstream speed up trick
    setlocale(LC_ALL, "C");
    ifstream fileOpt(argv[1]);
    ifstream fileBelady(argv[2]);
    uint64_t t, id, size;
    long double util, dvar, hit;
    string name;
    uint64_t cs, t2, id2, size2, hit2;

    unordered_map<pair<short int, short int>, uint64_t> hitStats;

    while(
          (fileOpt >> t >> id >> size >> util >> dvar >> hit)
          &&
          (fileBelady >> name >> cs >> t2 >> id2 >> size2 >> hit2)
          )
    {
        if(t!=t2 || id!=id2 || size!=size2) {
            cerr << "diffTrace t " << t << " t2 " << t2 << endl;
            return 1;
        }
        hitStats[make_pair(hit,hit2)]++;
    }

    for(auto it: hitStats) {
        std::cout << it.first.first << " " << it.first.second << " " << it.second << std::endl;
    }

    return 0;
}
