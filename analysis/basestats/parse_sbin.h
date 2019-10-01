#pragma once

#include <iostream>
#include <fstream>
#include <algorithm>

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


class SBinParser : public Parser {
protected:
    // parse tmps
    Req CurReq;

public:
    SBinParser()
        : Parser()
    {
        std::cerr << sizeof(CurReq) << "\n";
    }
    virtual void setFile(std::string fname) {
        infile.open(fname, std::fstream::in | std::fstream::binary);
    }

    virtual bool parseBatch(size_t parseReqs) {
        batch.clear();
        batch.reserve(parseReqs);
        bool parsed = false;

        while(true) {
            infile.read(reinterpret_cast<char*>(&CurReq), sizeof(CurReq));
            if(infile.eof() || infile.fail() || infile.bad()) {
                break;
            }
            parsed=true;
            // recall: endianness
            endswap(&CurReq.ts);
            endswap(&CurReq.oid);
            endswap(&CurReq.length);
            std::cerr << CurReq.ts << " " << CurReq.oid << "\n";
            batch.emplace_back(double(CurReq.ts)/1000000000,std::to_string(CurReq.oid),CurReq.length);
            if(--parseReqs == 0) {
                break;
            }
        }
        return parsed;
    }
};
            
static Factory<SBinParser> sbinparser("sbin");
