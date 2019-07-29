#include <fstream>
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>
 
using namespace std;

int main (int argc, char* argv[])
{

    if(argc < 4) {
        cerr << argv[0] << " sampleThresh reqCount inputFile1 inputFile2 [..]" << endl;
        return 1;
    }

    cerr << "started\n";

    // trace properties
    const uint64_t sampleThres  = std::stoull(argv[1]);
    const uint64_t reqCount  = std::stoull(argv[2]);

    std::string inputFiles[argc-2];
    for(int i=3; i<argc; i++) {
        inputFiles[i-3] = argv[i];
    }

    cerr << "parsed " << inputFiles[0] << " " << sampleThres << " " << reqCount/100 << " " << reqCount << "\n";

    ifstream infiles[argc-2];
    for(int i=3; i<argc; i++) {
        infiles[i-3].open(inputFiles[i-3]);
    }

    std::string f1, f2, f3, f4;
    std::unordered_map<std::string, std::unordered_set<size_t> > occurence;
    uint64_t reqs = 0;
    
    for(int i=3; i<argc; i++) {
        while (infiles[i-3] >> f1 >> f2 >> f3 >> f4)
        {
            reqs++;
            occurence[f2].insert(i-3);
            // if(reqs>reqCount/100) {
            //     break;
            // }
        }
    }

    std::unordered_set<std::string> trackThese;
    for(auto & it : occurence) {
        if(it.second.size()>1) {
            trackThese.insert(it.first);
            //            cout << it.first << " " << it.second.size() << "\n";
        }
    }

    cerr << "size of trackThese " << trackThese.size() << "\n";

    for(int i=3; i<argc; i++) {
        infiles[i-3].close();
        infiles[i-3].open(inputFiles[i-3]);
    }

    for(int i=3; i<argc; i++) {
        while (infiles[i-3] >> f1 >> f2 >> f3 >> f4)
        {
            if(trackThese.count(f2)>0) {
                cout << i-3 << " " << f1 << " " << f2 << "\n";
            }
            // if(reqs>reqCount) {
            //     break;
            // }
        }
    }

    cerr << "done\n";

    return 0;
}
