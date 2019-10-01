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
    if(argc != 4) {
        cerr << argv[0] << " inputFile format extraFields" << endl;
        return 1;
    }

    const string inputFile = argv[1];
    const string format = argv[2];
    const uint64_t extraFields = stoull(argv[3]);

    unique_ptr<Parser> p = move(Parser::create_unique(format));
    p->setFile(inputFile);
    p->setExtraFields(extraFields);

    Analysis a;

    while(p->parseBatch(1000000)){
        std::cerr << ".";
        a.processBatch(p->getBatch());
    }
    std::cerr << "\n";
    a.outputStats();

    return 0;
}
