#pragma once

#include "request.h"
#include <iostream>
#include <map>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Analysis {
protected:
    std::unordered_map<std::string, int64_t > counters;
    std::unordered_map<std::string, int64_t > ranks;
    std::map<std::string, std::vector<Request> > reqs;
    std::map<int64_t, int64_t > sizes;
    std::unordered_set<std::string> objids;
    std::unordered_set<std::string> onehitwonids;
    std::vector<int64_t> reqsizes;

public:
    void processBatch(ReqBatch & batch) {
        for(auto & req: batch) {
            counters["RequestCount"]++;
            counters["TotalBytes"]+=req.size;
            counters["TotalObjs"]++;
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
            // plot CDF
            sizes[req.size]++;
            // stddev, scv
            reqsizes.push_back(req.size);
            // one hit wonders
            std::vector<Request> v;
            if (reqs.count(req.oid)) {
                v = reqs[req.oid];
            }
            v.push_back(req);
            reqs[req.oid] = v;
            // rank requests
            ranks[req.oid]++;
        }
    }

    void outputStats() {
        for(auto & it: counters) {
            std::cout << it.first << " " << it.second << "\n";
        }
        double sum = 0;
        double mean = (double)counters["TotalBytes"] / (double)counters["RequestCount"];
        for(auto & it: reqsizes) {
            sum += (it - mean) * (it - mean);
        }
        double stddev = sqrt(sum / (double)counters["RequestCount"]);
        double scv = stddev * stddev / (mean * mean);
        std::cout << "Mean " << mean << "\n";
        std::cout << "StdDev " << stddev << "\n";
        std::cout << "SquaredCoeffVar " << scv << "\n";

        double maxTs = counters["MaxTs"];
        for (auto & it: reqs) {
            Request curr = it.second[0];
            if (it.second.size() == 1) {
                if (curr.ts < maxTs - (double)172800) {
                    counters["OneHitWondersObjs"]++;
                    counters["OneHitWondersBytes"]+=curr.size;
                    if(onehitwonids.count(curr.oid)==0) {
                        counters["UniqueOneHitWondersObjs"]++;
                        counters["UniqueOneHitWondersBytes"]+=curr.size;
                        onehitwonids.insert(curr.oid);
                    }
                }
            } else {
                for (std::size_t i=1; i<it.second.size(); ++i) {
                    if (curr.ts < it.second[i].ts - (double)172800) {
                        counters["OneHitWondersObjs"]++;
                        counters["OneHitWondersBytes"]+=curr.size;
                        if(onehitwonids.count(curr.oid)==0) {
                            counters["UniqueOneHitWondersObjs"]++;
                            counters["UniqueOneHitWondersBytes"]+=curr.size;
                            onehitwonids.insert(curr.oid);
                        }
                    }
                    curr = it.second[i];
                }
            }
        }
        std::cout << "% of One Hit Wonder Objects " << (double)counters["OneHitWondersObjs"] / (double)counters["TotalObjs"] * 100 << "\n";
        std::cout << "% of Unique One Hit Wonder Objects " << (double)counters["UniqueOneHitWondersObjs"] / (double)counters["UniqueObjs"] * 100 << "\n";
        std::cout << "% of One Hit Wonder Bytes " << (double)counters["OneHitWondersBytes"] / (double)counters["TotalBytes"] * 100 << "\n";
        std::cout << "% of Unique One Hit Wonder Bytes " << (double)counters["UniqueOneHitWondersBytes"] / (double)counters["UniqueBytes"] * 100 << "\n";
        std::cout << "% of Unique One Hit Wonder Requests " << (double)onehitwonids.size() / (double)objids.size() * 100 << "\n";
        // for(auto & it: reqs) {
        //     std::cout << it.first << "\n"; // << " " << it.second
        // }
        std::cout << "Ranks" << "\n";
        for(auto & it: ranks) {
            std::cout << it.first << " " << it.second << "\n";
        }
        std::cout << "Sizes" << "\n";
        for(auto & it: sizes) {
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
