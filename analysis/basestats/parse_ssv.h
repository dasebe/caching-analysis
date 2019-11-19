#pragma once

#include <iostream>
#include <fstream>

class SSVParser : public Parser {
protected:
    // parse tmps
    double ts;
    std::string oid;
    int64_t size;
    std::string tmp;

public:
    SSVParser()
        : Parser()
    {
    }
    virtual void setFile(std::string fname) {
        infile.open(fname);
    }

    virtual bool parseBatch(size_t parseReqs) {
        batch.clear();
        batch.reserve(parseReqs);
        bool parsed = false;
        while (infile >> ts >> oid >> size) {
            // parsing extra fields
            for(int i=0; i<extraFields; i++) {
                infile >> tmp;
            }
            if(!infile.good() || infile.eof()) {
                break;
            }
            parsed=true;
            batch.emplace_back(ts / 1.0e9,oid,size);
            if(--parseReqs == 0) {
                break;
            }
        }
        return parsed;
    }
};
            

static Factory<SSVParser> ssvparser("ssv");
