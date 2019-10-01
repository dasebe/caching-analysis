#pragma once

// disable threading as there seems to be a bug in csv.h
#define CSV_IO_NO_THREAD 1

#include <iostream>
#include "lib/csv.h"
#include <fstream>

class CSV8Parser : public Parser {
protected:
    typedef io::CSVReader<8, io::trim_chars<'"'>, io::no_quote_escape<','> > CSV8format;
    CSV8format * reader;
    // parse tmps
    double ts;
    std::string oid;
    int64_t size;
    size_t op_count;
    std::string op, tmp;
    bool read_header;

public:
    CSV8Parser()
        : Parser(), read_header(false)
    {
    }
    ~CSV8Parser()
    {
        delete reader;
    }
    virtual void setFile(std::string fname) {
        reader = new CSV8format(fname);
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
            if( (op.compare("READ")==0) || (op.compare("GET_RANGE")==0) || (op.compare("GET_EDGE")==0)) {
                parsed=true;
                for(size_t i=0; i<op_count; i++) {
                    batch.emplace_back(ts,oid,size);
                }
                if(--parseReqs == 0) {
                    break;
                }
            }
        }
        return parsed;
    }
};
            

static Factory<CSV8Parser> csv8parser("csv8");





/// 2nd type of parser

class CSV6Parser : public Parser {
protected:
    typedef io::CSVReader<6, io::trim_chars<'"'>, io::no_quote_escape<','> > CSV6format;
    CSV6format * reader;
    // parse tmps
    double ts;
    std::string oid;
    int64_t size;
    size_t op_count;
    std::string op, tmp;
    bool read_header;

public:
    CSV6Parser()
        : Parser(), read_header(false)
    {
    }
    ~CSV6Parser()
    {
        delete reader;
    }
    virtual void setFile(std::string fname) {
        reader = new CSV6format(fname);
        reader->read_header(io::ignore_missing_column, "op_time","key","op","op_count","size","result");
    }

    virtual bool parseBatch(size_t parseReqs) {
        batch.clear();
        batch.reserve(parseReqs);
        bool parsed = false;
        while(reader->read_row(ts,
                               oid,
                               op,op_count,
                               size,
                               tmp
                               )
              ) {
            if(op.compare("FIND")!=0) {
                continue;
            }
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
            

static Factory<CSV6Parser> csv6parser("csv6");






class CSV7Parser : public Parser {
protected:
    typedef io::CSVReader<7, io::trim_chars<'"'>, io::no_quote_escape<','> > CSV7format;
    CSV7format * reader;
    // parse tmps
    double ts;
    std::string oid;
    int64_t size;
    size_t op_count;
    std::string op, tmp;
    bool read_header;

public:
    CSV7Parser()
        : Parser(), read_header(false)
    {
    }
    ~CSV7Parser()
    {
        delete reader;
    }
    virtual void setFile(std::string fname) {
        reader = new CSV7format(fname);
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
                               tmp // cache hits
                               )
              ) {
            if(op.compare("GET")!=0) {
                continue;
            }
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
            

static Factory<CSV7Parser> csv7parser("csv7");

