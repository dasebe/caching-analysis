#include <iostream>
#include "request.h"
#include "analyze.h"
#include "parse_ssv.h"
 
using namespace std;

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 3) {
        cerr << argv[0] << " inputFile extraFields" << endl;
        return 1;
    }

    const char* inputFile = argv[1];
    const uint64_t extraFields = stoull(argv[2]);


    Parser p(inputFile,extraFields);
    Analysis a;

    while(p.parseBatch(100000)){
        std::cerr << ".";
        a.processBatch(p.getBatch());
    }
    std::cerr << "\n";
    a.outputStats();

    return 0;
}
