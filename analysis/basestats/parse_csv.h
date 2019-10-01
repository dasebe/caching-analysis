#pragma once

// disable threading as there seems to be a bug in csv.h
#define CSV_IO_NO_THREAD 1

#include <iostream>
#include "lib/csv.h"
#include <fstream>

class CSVParser : public Parser {
protected:
    typedef io::CSVReader<8, io::trim_chars<'"'>, io::no_quote_escape<','> > CSVformat;
    CSVformat * reader;
    // parse tmps
    double ts;
    std::string oid;
    int64_t size;
    size_t op_count;
    std::string op, tmp;

public:
    CSVParser()
        : Parser()
    {
    }
    ~CSVParser()
    {
        delete reader;
    }
    virtual void setFile(std::string fname) {
        reader = new CSVformat(fname);
        reader->read_header(io::ignore_missing_column, "op_time","fbid","delta","op","op_count","size","cache_hits","shard");
    }

    virtual bool parseBatch(size_t parseReqs) {
        batch.clear();
        batch.reserve(parseReqs);
        bool parsed = false;
        while(reader->read_row(ts,
                               oid,
                               tmp,
                               op,op_count,
                               size,
                               tmp,tmp
                               )
              ) {
            //            std::cerr << ts << " " << oid << " " << op << "\n";
            parsed=true;
            for(size_t i=0; i<op_count; i++) {
                batch.emplace_back(ts,oid,size);
            }
            if(--parseReqs == 0) {
                break;
            }
        }
        return parsed;
    }
};
            

static Factory<CSVParser> csvparser("csv");

