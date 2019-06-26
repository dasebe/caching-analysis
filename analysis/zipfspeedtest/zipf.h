#include <math.h>
#include <iostream>
#include <fstream>
#include <cassert>
#include <functional>
#include <algorithm>
#include <string>
#include <vector>
#include <unordered_map>
#include <map>
#include <random>

/* sampling object id and object size from a Zipf-like distribution
 (aka the independent reference model (IRM))

 Multiple objects with similar rates are grouped together for more efficient sampling.
 Two level sampling process: first skewed sample to select the rate, then uniform sample within rate to select object.
*/


class ZipfRequests {

private:
    typedef std::pair<int64_t, int64_t> IdSizePair;

    std::mt19937_64 rd_gen;
    std::vector<std::vector<IdSizePair> > popDist;
    std::uniform_int_distribution<size_t> popOuterRng;
    std::vector<std::uniform_int_distribution<size_t> > popInnerRngs;

    std::unordered_map<int64_t, IdSizePair> stats;

public:
    ZipfRequests(std::string sizeFile, int64_t objCount, double zipfAlpha) {

        // init
        rd_gen.seed(1);

        // try to scan object sizes from file
        std::vector<int64_t> base_sizes;
        if(sizeFile.size()>0) {
            std::ifstream infile;
            infile.open(sizeFile);
            int64_t tmp;
            while (infile >> tmp) {
                if(tmp>0 && tmp<4096) {
                    base_sizes.push_back(tmp);
                }
            }
            infile.close();
        }
        if(base_sizes.size()==0) {
            base_sizes = std::vector<int64_t>({16,32,64,100,128,200,256,300,100,128,200,256,300,100,128,200,256,300,100,128,200,256,300,100,128,200,256,300,400,700,900,512,1024,800,1400,1500,2048,4096});
        }
        std::uniform_int_distribution<uint64_t> size_dist(0,base_sizes.size()-1);

        // initialize popularity dist
        // group buckets of "similarly popular" objects (adding up to zipf-rate 1)
        popDist.push_back(std::vector<IdSizePair>());
        double ratesum = 0;
        int64_t popBucket=0;
        int64_t objectId=1;
        for(; objectId < objCount; objectId++) {
            ratesum += 1.0/pow(double(objectId), zipfAlpha);
            popDist[popBucket].push_back(
                                         IdSizePair(
                                                    objectId,
                                                    base_sizes[size_dist(rd_gen)]
                                                    )
                                         );
            if(ratesum>1) {
                // std::cerr << "init " << objectId << " " << ratesum << "\n";
                // move to next popularity bucket
                popDist.push_back(std::vector<IdSizePair>());
                popBucket++;
                ratesum=0;
            } 
        }
        // std::cerr << "init " << objectId << " " << ratesum << "\n";
        // corresponding PNRGs
        popOuterRng = std::uniform_int_distribution<size_t>(0,popDist.size()-1);
        for(size_t i=0; i<popDist.size(); i++) {
            popInnerRngs.push_back(std::uniform_int_distribution<size_t>(0,popDist[i].size()-1));
        }
        std::cerr << "zipf debug objectCount " << popDist.size() << " largest bucket size" << popDist[popDist.size()-1].size() << " effective probability " << 1.0/popDist.size() * 1.0/popDist[popDist.size()-1].size() << " theoretical probability " << 1/pow(double(objCount), zipfAlpha) << "\n";
    }


    void Sample(uint64_t & id, uint64_t & size) {
        // two step sample
        const size_t outerIdx = popOuterRng(rd_gen);
        const size_t innerIdx = popInnerRngs[outerIdx](rd_gen);
        // std::cerr << outerIdx << " " << innerIdx << "\n";
        const IdSizePair sample = (popDist[outerIdx])[innerIdx];
        id=sample.first; // return values
        size=sample.second; // return values
        if(stats.count(id)>0) {
            stats[id].second++;
        } else {
            stats[id].first = size;
            stats[id].second = 1;
        }
    }

    void Summarize() {
        std::map<int64_t, IdSizePair> summary;
        for(auto it: stats) {
            summary[it.second.second] = IdSizePair(it.first, it.second.first);
        }
        //        int64_t top=10;
        int64_t summed_bytes = 0;
        int64_t idx = 0;
        std::map<int64_t, IdSizePair>::reverse_iterator rit = summary.rbegin();
        for (; rit!= summary.rend(); ++rit) {
            summed_bytes += rit->second.second;
            std::cerr << idx++ << " " << rit->first << " " << rit->second.first << " " << rit->second.second << " " << summed_bytes << "\n";
            // if(--top <1 ) {
            //     break;
            // }
        }
    }
};
