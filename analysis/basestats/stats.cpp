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

    Parser p(argv[1]);
    Analysis a;

    while(p.parseBatch(10)){
        a.processBatch(p.getBatch());
    }
    a.outputStats();

    return 0;
}
