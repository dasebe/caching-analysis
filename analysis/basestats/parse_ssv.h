#include <fstream>

class Parser {
protected:
    const std::string traceName;
    std::ifstream infile;

    // parse tmps
    int64_t ts;
    std::string oid;
    int64_t size;

    // request batch to be handed out
    ReqBatch batch;

public:
    Parser(std::string fname)
        : traceName(fname), infile(fname)
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
            



