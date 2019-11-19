#include <iostream>
#include "request.h"
#include "analyze.h"
#include "parse.h"
#include "parse_ssv.h"
#include "parse_sbin.h"
#include "parse_tsv.h"
#include "parse_csv.h"

using namespace std;

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc < 4) {
        cerr << argv[0] << " format extraFields inputFile1 [inputFile2] [inputFile3] .." << endl;
        return 1;
    }

    const string format = argv[1];
    const uint64_t extraFields = stoull(argv[2]);
    unique_ptr<Parser> p = Parser::create_unique(format);
    p->setExtraFields(extraFields);

    Analysis a;

    std::cerr << "started";

    for(int argidx = 3; argidx<argc; argidx++) {
        const string inputFile = argv[argidx];
        p->setFile(inputFile);
        std::cerr << "\n processing " << inputFile << " ";
        while(p->parseBatch(1000000)){
            std::cerr << ".";
            a.processBatch(p->getBatch());
        }
        a.outputStats(argidx);
        p->closeFile(inputFile);
    }
    std::cerr << "\n";

    return 0;
}
