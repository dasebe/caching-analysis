#include <iostream>
#include <fstream>

class Parser {
protected:
    const std::string traceName;
    std::ifstream infile;
    int extraFields;

    // parse tmps
    int64_t ts;
    std::string oid;
    int64_t size;
    std::string tmp;

    // request batch to be handed out
    ReqBatch batch;

public:
    Parser(std::string fname, int nextraFields)
        : traceName(fname), infile(fname), extraFields(nextraFields)
    {
    }
    ~Parser() {
        infile.close();
    }
    bool parseBatch(size_t parseReqs) {
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
            batch.emplace_back(double(ts),oid,size);
            if(--parseReqs == 0) {
                break;
            }
        }
        return parsed;
    }

    ReqBatch & getBatch() {
        return batch;
    }
};
            



