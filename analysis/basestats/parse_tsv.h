#pragma once

// disable threading as there seems to be a bug in csv.h
#define CSV_IO_NO_THREAD 1

#include <iostream>
#include "lib/csv.h"
#include <fstream>

class TSVParser : public Parser {
protected:
    typedef io::CSVReader<12, io::trim_chars<' '>, io::no_quote_escape<'\t'> > CSVformat;
    CSVformat * reader;
    // parse tmps
    double ts;
    std::string oid;
    int64_t osize;
    int64_t reqsize;
    std::string tmp;

public:
    TSVParser()
        : Parser()
    {
    }
    ~TSVParser()
    {
        delete reader;
    }
    virtual void setFile(std::string fname) {
        reader = new CSVformat(fname);
    }

    virtual bool parseBatch(size_t parseReqs) {
        batch.clear();
        batch.reserve(parseReqs);
        bool parsed = false;
        while(reader->read_row(ts,
                             tmp,tmp,tmp,tmp,
                             oid,
                             tmp,tmp,tmp,
                             osize,reqsize,
                             tmp
                               )
              ) {
            parsed=true;
            batch.emplace_back(ts,oid,reqsize);
            if(--parseReqs == 0) {
                break;
            }
        }
        return parsed;
    }
};
            

static Factory<TSVParser> tsvparser("tsv");

