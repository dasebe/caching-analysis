#include <fstream>
#include <iostream>
#include <unordered_map>
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
    unordered_map<string, uint32_t > globalObjs;

    string id;
    int64_t t, tmp;
    uint64_t size;
    uint64_t totalReqs = 0;

    // determine one-hit-wonders
    while (infile >> t >> id >> size)
    {
        // parsing
        for(uint64_t i=0; i<extraFields; i++) {
            // read other fields
            infile >> tmp;
        }
        totalReqs++;
        if(globalObjs[id] < 1000002) {
            globalObjs[id]++;
        }
    }
    // sample 10 popular elements
    unordered_map<string, string> sampledObjs;
    for(auto & it: globalObjs) {
        if(it.second > 1000000) {
            const string idx = to_string(sampledObjs.size());
            sampledObjs[it.first] = idx;
        }
        if(sampledObjs.size() >= 100) {
            break;
        }
    }
    std::cerr << inputFile << " first pass " << totalReqs << " " << globalObjs.size() << "\n";
    globalObjs.clear();

    // reset file
    infile.clear();
    infile.seekg(0, ios::beg);
    // Zhenyu: not assume t start from any constant, so need to compute the first window
    infile>>t;
    int64_t timeWindowEnd = interval * (t/interval + (t%interval != 0));
    infile.clear();
    infile.seekg(0, ios::beg);

    // determine most popular objects overall, how many requests to each (decay rate)
    // number of popular objects from previous window!!
    // Zhenyu: stats are collected every window, where the first window is from [0, interval), and second is [interval, 2*interval)
    while (infile >> t >> id >> size)
    {
        // parsing
        for(uint64_t i=0; i<extraFields; i++) {
            // read other fields
            infile >> tmp;
        }
        while (t >= timeWindowEnd) { // in seconds
            for(auto & it: intstats) {
                outfile << inputFile << " " << timeWindowEnd << " " << it.first << " " << it.second << "\n";
                it.second = 0;
            }
            intobjs.clear();
            timeWindowEnd += interval;
        }
        // stats
        intstats["RequestCount"]++;
        intstats["RequestedBytes"]+=size;
        // unique objs in this interval
        if(intobjs.count(id)==0) {
            intobjs[id] = 1;
            intstats["UniqueHourlyObjects"]++;
            intstats["UniqueHourlyBytes"]+=size;
            //assume one hit wonders
            ++intstats["SegmentOneHitWonders"];
        } else if (intobjs.find(id)->second == 1) {
            //remove from one hit wonders
            intobjs[id] += 1;
            --intstats["SegmentOneHitWonders"];
        }
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
        // rough reuse distances
        if(globalObjs.count(id) == 0) {
            // first access
            intstats["RD-Inf"]++;
            intstats["OneHitWonders"]++;
            globalObjs[id] = t;
        } else {
            if ( (t-globalObjs[id]) < 60 ) {
                intstats["RD-Minute"]++;
            } else if ( (t-globalObjs[id]) < 60*60 ) {
                intstats["RD-Hour"]++;
            } else if ( (t-globalObjs[id]) < 60*60*24 ) {
                intstats["RD-Day"]++;
            } else if ( (t-globalObjs[id]) < 60*60*24*2 ) {
                intstats["RD-2Days"]++;
            } else {
                intstats["RD-G2Days"]++;
            }
        }
        // popular objects
        if(sampledObjs.count(id)>0) {
            intstats["SampledObject"+sampledObjs[id]]++;
        }
    }

    {
        //partial segment
        for(auto & it: intstats) {
            outfile << inputFile << " " << timeWindowEnd << " " << it.first << " " << it.second << "\n";
        }
    }

    outfile << inputFile << " " << 0 << " " << "UniqueObjects" << " " << globalObjs.size() << "\n";

    infile.close();
    outfile.close();

    return 0;
}
