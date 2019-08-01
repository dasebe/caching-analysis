#include <fstream>
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>
 
using namespace std;

int main (int argc, char* argv[])
{

    if(argc < 4) {
        cerr << argv[0] << " sampleThresh(3) reqCount(1e7) inputFile1 inputFile2 [..]" << endl;
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

    cerr << "parsed " << inputFiles[0] << " " << sampleThres << " " << reqCount/10 << " " << reqCount << "\n";

    ifstream infiles[argc-2];
    for(int i=3; i<argc; i++) {
        infiles[i-3].open(inputFiles[i-3]);
    }

    uint64_t t;
    std::string f2, f3, f4;
    std::unordered_map<std::string, std::unordered_set<size_t> > occurence;
    uint64_t reqs = 0;
    
    for(int i=3; i<argc; i++) {
        while (infiles[i-3] >> t >> f2 >> f3 >> f4)
        {
            reqs++;
            occurence[f2].insert(i-3);
            if(reqs>reqCount/10) {
                break;
            }
        }
        cerr << "read " << reqs << " for trace " << i << "\n";
        reqs=0;
    }

    std::unordered_set<std::string> trackThese;
    for(auto & it : occurence) {
        if(it.second.size()>sampleThres) {
            trackThese.insert(it.first);
            //            cout << it.first << " " << it.second.size() << "\n";
        }
    }

    cerr << "size of trackThese " << trackThese.size() << "\n";

    for(int i=3; i<argc; i++) {
        infiles[i-3].close();
        infiles[i-3].open(inputFiles[i-3]);
    }

    std::unordered_map<size_t, std::unordered_map<std::string, uint64_t> > lastSeen;
    for(int i=3; i<argc; i++) {
        while (infiles[i-3] >> t >> f2 >> f3 >> f4)
        {
            if(trackThese.count(f2)>0) {
                if((lastSeen[i-3])[f2]==0 || (t - (lastSeen[i-3])[f2] )>60 ) {
                    // not recently seen, or seen more than 60s ago
                    cout << i-3 << " " << t << " " << f2 << "\n";
                }
                (lastSeen[i-3])[f2] = t;
            }
            
            if(reqs>reqCount) {
                break;
            }
        }
    }

    cerr << "done\n";

    return 0;
}
