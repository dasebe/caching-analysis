#include <iostream>
#include <fstream>
#include <unordered_map>
#include <map>
#include <algorithm>
#include <math.h>


template <class T>
inline void endswap(T *objp)
{
  unsigned char *memp = reinterpret_cast<unsigned char*>(objp);
  std::reverse(memp, memp + sizeof(T));
}
using namespace std;

#pragma pack(1)
struct Req
{
    int64_t ts;
    int64_t client_machine;
    int64_t rack ;
    int64_t dataset;
    int64_t oid;
    int64_t readid1;
    int64_t readid2;
    int64_t offset;
    int32_t length;
    int64_t jobid;
};

unordered_map< string, unordered_map < int64_t, uint64_t > > dists;
inline void dist(string name, int64_t value) {
    (dists[name])[value]++;
}

unordered_map<string, uint64_t > readids;

int64_t prev_ts = -1, first_ts;
uint64_t reqs=0;
uint64_t zeroIa=0, negIa=0;

int main (int args, char *argv[]) {
    Req CurReq;


    for(int ag=1; ag<args; ag++) {
        //        cerr << argv[ag] << "\n";

        std::fstream fh;
        fh.open(argv[ag], std::fstream::in | std::fstream::binary);

        // get distributions of IA-time, etc.

        while(!fh.eof() && !fh.fail() && !fh.bad()) {
            fh.read(reinterpret_cast<char*>(&CurReq), sizeof(CurReq));
            // recall: endianness
            endswap(&CurReq.ts);
            if(prev_ts!=-1) {
                if(CurReq.ts==prev_ts) {
                    zeroIa++;
                } else if (CurReq.ts < prev_ts) {
                    negIa++;
                }
            } else {
                first_ts = CurReq.ts;
            }
            prev_ts=CurReq.ts;
            reqs++;
        }
        fh.close();

        cout << argv[ag] << " " << first_ts << " " << prev_ts << " " << reqs << " " << zeroIa << " " << negIa << "\n";
    }
    return 0;
    }
