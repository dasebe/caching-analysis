#pragma once

#include "request.h"
#include <iostream>
#include <unordered_map>
#include <unordered_set>

class Analysis {
protected:
    std::unordered_map<std::string, int64_t > counters;
    std::unordered_set<std::string> objids;

public:
    void processBatch(ReqBatch & batch) {
        for(auto & req: batch) {
            counters["RequestCount"]++;
            counters["TotalBytes"]+=req.size;
            if(objids.count(req.oid)==0) {
                counters["UniqueObjs"]++;
                counters["UniqueBytes"]+=req.size;
                objids.insert(req.oid);
            }
            if(req.size > counters["MaxObjSize"]) {
                counters["MaxObjSize"] = req.size;
            }
        }
    }

    void outputStats() {
        for(auto & it: counters) {
            std::cout << it.first << " " << it.second << "\n";
        }
    }
};


/* OLD ANALYSIS CODE

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


*/
