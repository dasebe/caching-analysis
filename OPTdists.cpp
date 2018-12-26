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
    uint64_t t, id, size;
    long double util, dvar, hit;

    unordered_map<std::pair<uint64_t, uint64_t>, entry> caches;
    //    map<double, long double> stayLen;
    map<uint64_t, long double> stayInts;
    
    unordered_map<std::pair<uint64_t, uint64_t>, oStat> ostat;

    uint64_t ourTime = 0;
    while(file >> t >> id >> size >> util >> dvar >> hit) {
        auto idS = std::make_pair(id,size);
        if(caches.count(idS) > 0) {
            // decreased dvar by more than 10%
            if(dvar < caches[idS].dvar*0.9) {
                double curLen = ourTime - caches[idS].t;
                //                stayLen[round(100.0*log10(curLen))/100.0]+=caches[idS].dvar-dvar;
                stayInts[caches[idS].intCount]+=caches[idS].dvar-dvar;
                caches[idS].intCount=1;
                ostat[idS].evicted+=caches[idS].dvar-dvar;
            } else {
                caches[idS].intCount++;
            }
                
        }
        // increased dvar by more than 10%
        if (dvar > caches[idS].dvar*1.1) {
            caches[idS].intCount=1;
            ostat[idS].admitted+=dvar-caches[idS].dvar;
        }
        caches[idS].t = ourTime;
        caches[idS].dvar = dvar;
        ostat[idS].hits+=hit;
        ostat[idS].reqCount++;
        ostat[idS].size=size;
        ourTime++;
    }

    for(auto it: stayInts) {
        std::cout << it.first << " " << it.second << std::endl;
    }

    for(auto it: ostat) {
        std::cerr << it.second.admitted << " " << it.second.evicted << " " << it.second.hits << " " << it.second.size << " " << it.second.reqCount << std::endl;
    }

    return 0;
}
