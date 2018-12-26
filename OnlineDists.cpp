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

struct entry {
    uint64_t t;
    long double dvar;
    uint64_t intCount;

    entry()
        : t(0), dvar(0), intCount(1)
    {}
} ;

struct oStat {
    long double admitted;
    long double evicted;
    long double hits;
    uint64_t size;
    uint64_t reqCount;

    oStat()
        : admitted(0), evicted(0), hits(0), size(0), reqCount(0)
    {}
} ;


// main
int main(int argc, char* argv[])
{
    // I/O ifstream speed up trick
    setlocale(LC_ALL, "C");
    ifstream file(argv[1]);
    std::string sname, snamePrev, finalName;
    uint64_t csize, t, id, size;
    long double hit;

    //    unordered_map<std::pair<uint64_t, uint64_t>, oStat> ostat;

    uint64_t ourTime = 0;
    for(int i=0; i<2; i++) {
        unordered_map<std::pair<uint64_t, uint64_t>, bool> inCache;
        unordered_map<std::pair<uint64_t, uint64_t>, bool> lastInCache;
        uint64_t cacheSize = 0, reqs = 0, hits = 0;
        uint64_t cacheSizeSum = 0, cacheSizeMax = 0;
        
        while(file >> sname >> csize >> t >> id >> size >> hit) {
            auto idS = std::make_pair(id,size);
            reqs++;
            if(hit>0) {
                hits++;
                if(!lastInCache[idS]) {
                    // must have entered to create this hit
                    cacheSize += size;
                }
                lastInCache[idS] = true;
            } else {
                if(lastInCache[idS]) {
                    // must have entered but got evicted
                    cacheSize -= size;
                }
                lastInCache[idS] = false;
            }
            cacheSizeSum += cacheSize;
            if(cacheSize > cacheSizeMax)
                cacheSizeMax = cacheSize;
            if(snamePrev.length()>0 &&  sname!=snamePrev) {
                finalName = snamePrev;
                snamePrev = sname;
                break;
            }
            snamePrev = sname;
            finalName = sname;
        }
        std::cout << finalName <<  " " << csize << " " << reqs << " " << hits << " " << cacheSize << " " << cacheSizeSum << " " << cacheSizeMax << std::endl;

    }


    return 0;
}
