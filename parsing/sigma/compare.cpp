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

int main (int args, char *argv[]) {
    Req CurReq;

    int skip = stoi(argv[2]);
    int rows = stoi(argv[3]);
    cerr << "parsing " << argv[1] << " skip " << skip << " rows " << rows << "\n";
    std::fstream fh;
    fh.open(argv[1], std::fstream::in | std::fstream::binary);

    uint64_t reqs = 0;

    while(true) {
        // parse
        fh.read(reinterpret_cast<char*>(&CurReq), sizeof(CurReq));
        if(fh.eof() || fh.fail() || fh.bad()) {
            break;
        }
        // cond output
        reqs++;
        if(reqs>=skip) {
            endswap(&CurReq.ts);
            cout << CurReq.ts << "\n";
        }
        if(reqs>=rows+skip) {
            break;
        }
    }
    fh.close();
    return 0;
}
