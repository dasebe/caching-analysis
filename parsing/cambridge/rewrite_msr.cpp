# include "lib/csv.h"
#include <iostream>
#include <unordered_map>

int main(int argc, char *argv[]) {

    struct trace {
        io::CSVReader<7> * reader;
        uint64_t ts;
        uint64_t ts_start;
        uint64_t appid;
    };
    uint64_t ts=0;
    std::string app, act;
    int disk;
    uint64_t offset;
    uint64_t size;
    uint64_t resptime;
    std::unordered_map<std::string, uint64_t> opid;

    std::unordered_map<std::string, trace> traces;
    for(int i=1; i<argc; i++) {
        traces[argv[i]].reader = new io::CSVReader<7>(argv[i]);
        traces[argv[i]].reader->set_header("ts", "app", "disk", "act" ,"offest","size","resptime");
        traces[argv[i]].reader->read_row(ts, app, disk, act, offset, size, resptime);
        traces[argv[i]].ts_start=ts;
        traces[argv[i]].ts=0;
        traces[argv[i]].appid = traces.size()-1;
        std::cerr << "added " << argv[i] << " as " << traces[argv[i]].appid << "\n";
    }

    //    size_t count = 0;
    while(traces.size()>0) {
        uint64_t lowTS = (traces.begin())->second.ts;
        for(auto & it: traces) {
            if(it.second.ts < lowTS) {
                lowTS = it.second.ts;
            }
        }
        for(auto & it: traces) {
            //std::cerr << "ddd " << it.first << " " << it.second.ts <<  " " << lowTS << "\n";
            if(it.second.ts <= lowTS) {
                //std::cerr << "sss " << it.first << " " << it.second.ts << " " << lowTS << "\n";
                if(it.second.reader->read_row(ts, app, disk, act, offset, size, resptime)) {
                    if(opid.count(act)==0) {
                        const auto prevc=opid.size();
                        opid[act] = prevc; // unique id
                    }
                    std::cout << it.second.ts << " " << std::to_string(disk)+ std::to_string(offset) << " " << size << " " << it.second.appid << " " << opid[act] << "\n";
                    it.second.ts=ts - it.second.ts_start;
                } else {
                    // end of file
                    traces.erase(it.first);
                    break;
                }
            }
        }
        // if(count++>100) {
        //     break;
        // }
    }

}

