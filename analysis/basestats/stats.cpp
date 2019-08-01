#include <fstream>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <map>
 
using namespace std;
 
int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 5) {
        cerr << argv[0] << " inputFile outputFile extraFields interval" << endl;
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];
    const char* outputFile = argv[2];
    const uint64_t extraFields = stoull(argv[3]);
    const int64_t interval = stoull(argv[4]);

    ifstream infile(inputFile);
    ofstream outfile(outputFile);

    cerr<< "started "
        << inputFile << " "
        << outputFile << "\n";
    
    map<string, uint64_t> intstats;
    unordered_map<string, uint64_t > intobjs;
    unordered_map<string, uint64_t > totalobjs;

    std::string id;
    int64_t t, tmp;
    uint64_t size;
    uint64_t totalReqs = 0;
    int64_t lastPrint = 0;

    while (infile >> t >> id >> size)
    {
        // parsing
        for(uint64_t i=0; i<extraFields; i++) {
            // read other fields
            infile >> tmp;
        }
        // check and print
        if(t - lastPrint > interval) { // in seconds
            for(auto & it: intstats) {
                outfile << inputFile << " " << t << " " << it.first << " " << it.second << "\n";
                it.second = 0;
            }
            intobjs.clear();
            lastPrint = t;
        }
        // stats
        totalReqs++;
        intstats["RequestCount"]++;
        intstats["RequestedBytes"]+=size;
        // unique objs
        if(intobjs.count(id)==0) {
            intobjs[id] = 1;
            intstats["UniqueObjects"]++;
            intstats["UniqueBytes"]+=size;
        }
        totalobjs[id]++;
        // osizes
        if(intstats["ObjectSize_Min"]==0) {
            intstats["ObjectSize_Min"] = size;
        }
        if(size<intstats["ObjectSize_Min"]) {
            intstats["ObjectSize_Min"] = size;
        }
        if(size>intstats["ObjectSize_Max"]) {
            intstats["ObjectSize_Max"] = size;
        }
    }

    infile.close();
    outfile.close();

    return 0;
}
