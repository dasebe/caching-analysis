#include <iostream>
#include <string>
#include <chrono>
#include "zipf.h"

uint64_t cache_sim(uint64_t id, uint64_t size) {
    auto r = id+size;
    return r;
}

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 4) {
        std::cerr << argv[0] << " objCount zipfAlpha traceLength\n";
        return 1;
    }

    // param parsing
    const int64_t objCount = std::stoull(argv[1]);
    const double zipfAlpha = std::stof(argv[2]);
    const int64_t traceLength = std::stoull(argv[3]);

    // init zipf distribution
    auto zr = ZipfRequests("size.dist", objCount, zipfAlpha);
    
    uint64_t reqcount = 0;
    auto t_start = std::chrono::high_resolution_clock::now();
    uint64_t id, size;

    for(int64_t i=0; i<traceLength; i++) {
        zr.Sample(id, size);
        cache_sim(id, size);
        if(reqcount > 10000) {
            auto t_end = std::chrono::high_resolution_clock::now();
            auto dur_ms = std::chrono::duration<double, std::milli>(t_end-t_start).count();
            std::cout << reqcount / (dur_ms/1000.0) << "\n";
            reqcount = 0;
            t_start = std::chrono::high_resolution_clock::now();
        }
    }
    
    return 0;
}
