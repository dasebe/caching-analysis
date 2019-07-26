#include <fstream>
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>
 
using namespace std;

int main (int argc, char* argv[])
{

    if(argc != 4) {
        cerr << argv[0] << " inputFile sampleThresh reqCount" << endl;
        return 1;
    }

    cerr << "started\n";

    // trace properties
    const char* inputFile = argv[1];
    const uint64_t sampleThres  = std::stoull(argv[2]);
    const uint64_t reqCount  = std::stoull(argv[3]);

    cerr << "parsed " << inputFile << " " << sampleThres << " " << reqCount/100 << " " << reqCount << "\n";

    ifstream infile(inputFile);

    std::string f1, f2, f3, f4;
    std::unordered_map<std::string, uint64_t> counts;
    uint64_t reqs = 0;
    
    while (infile >> f1 >> f2 >> f3 >> f4)
    {
        reqs++;
        counts[f2]++;
        if(reqs>reqCount/100) {
            break;
        }
    }

    infile.close();

    cerr << "sampling\n";
    std::unordered_set<std::string > sampled;
    for(auto & it: counts) {
        if(it.second>sampleThres) {
            sampled.insert(it.first);
        }
    }
    cerr << "sampled\n";

    infile.open(inputFile);
    reqs = 0;
    while (infile >> f1 >> f2 >> f3 >> f4)
    {
        reqs++;
        if(sampled.count(f2)>0) {
            cout << inputFile << " " << f1 << " " << f2 << "\n";
        }
        if(reqs>reqCount) {
            break;
        }
    }
    cerr << "done\n";

    return 0;
}
