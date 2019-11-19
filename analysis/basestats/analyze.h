#pragma once

#include "request.h"
#include <cmath>
#include <iostream>
#include <map>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Analysis {
protected:
    struct requestStat{
        uint64_t request_count;
        double last_seen_ts;
        bool two_days_seen;
    };
    std::unordered_map<std::string, requestStat > reqs;
    std::unordered_map<std::string, int64_t > counters;
    std::map<int64_t, int64_t > reqranks;
    std::map<int64_t, int64_t > sizes;
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
            // object sizes
            if(req.size > counters["MaxObjSize"]) {
                counters["MaxObjSize"] = req.size;
            }
            if(counters["MinObjSize"]==0) {
                counters["MinObjSize"] = req.size;
            } else if(req.size < counters["MinObjSize"]) {
                counters["MinObjSize"] = req.size;
            }
            // timestamps
            if(req.ts > counters["MaxTs"]) {
                counters["MaxTs"] = req.ts;
            }
            if(counters["MinTs"]==0) {
                counters["MinTs"] = req.ts;
            } else if(req.ts < counters["MinTs"]) {
                counters["MinTs"] = req.ts;
            }
            // stddev, scv, size CDF
            sizes[req.size]++;
            // track greater than 2 day intervals
            if (reqs.count(req.oid)) {
                if (req.ts - 172800.0 > reqs[req.oid].last_seen_ts) {
                    counters["Greater2daysInterval"]++;
                }
                reqs[req.oid].request_count++;
                reqs[req.oid].last_seen_ts = req.ts;
                reqs[req.oid].two_days_seen = false;
            } else {
                counters["Greater2daysInterval"]++;
                reqs[req.oid] = requestStat {1, req.ts, true};
            }
        }
    }

    void outputStats(int fileIdx) {
        for(auto & it: counters) {
            std::cout << fileIdx << " " << it.first << " " << it.second << " 0 \n";
        }
        double sum = 0;
        double mean = (double)counters["TotalBytes"] / (double)counters["RequestCount"];
        for(auto & it: sizes) {
            sum += ((it.first - mean) * (it.first - mean)) * it.second;
        }
        double stddev = sqrt(sum / (double)counters["RequestCount"]);
        double scv = stddev * stddev / (mean * mean);
        std::cout << fileIdx << " " << "Mean " << mean << " 0 \n";
        std::cout << fileIdx << " " << "StdDev " << stddev << " 0 \n";
        std::cout << fileIdx << " " << "SquaredCoeffVar " << scv << " 0 \n";

        std::cout << fileIdx << " " << "Greater2daysInterval " << counters["Greater2daysInterval"] << " 0 \n";
        int count = 0;
        for (auto & it: reqs) {
            if (it.second.two_days_seen) {
                count++;
            }
            reqranks[it.second.request_count]++;
        }
        std::cout << fileIdx << " " << "OneHitWonders " << count << " 0 \n";
        
        for (auto & it: reqranks) {
            std::cout << fileIdx << " Ranks " << it.first << " " << it.second << "\n";
        }

        for(auto & it: sizes) {
            std::cout << fileIdx << " Sizes " << it.first << " " << it.second << "\n";
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
