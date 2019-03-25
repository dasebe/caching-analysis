#include "lib/csv.h"
#include <iostream>
#include <unordered_map>

int main(int argc, char *argv[]) {

    int tcp_flags_syn, tcp_flags_fin;
    std::string ip_src, ip_dst, _ws_col_Protocol;
    std::string tcp_srcport, tcp_dstport, udp_srcport, udp_dstport, ip_proto;
    uint64_t ip_len = 0, ip_len_bucket;

    struct flow{
        uint64_t id;
        uint64_t count;
    };
    std::unordered_map<std::string, flow> flowid;
    std::unordered_map<std::string, uint64_t> protoid;
    std::unordered_map<int,uint64_t> ip_lens;

    //    int limit = 1000;
    std::string fivetuple;
    
    uint64_t reqcount = 0;

    for(int i=1; i<argc; i++) {
        io::CSVReader<11> reader(argv[i]);

        //    reader->set_header("ts", "app", "disk", "act" ,"offest","size","resptime");
        while(reader.read_row(
                               tcp_flags_syn,tcp_flags_fin,ip_src,ip_dst,
                               tcp_srcport,tcp_dstport,udp_srcport,udp_dstport,
                               ip_proto,ip_len,_ws_col_Protocol)
              )
        {
            fivetuple.clear();
            if(_ws_col_Protocol.compare("TCP")==0) {
                fivetuple = _ws_col_Protocol+ip_src+ip_dst+tcp_srcport+tcp_dstport;
            } else if(_ws_col_Protocol.compare("UDP")==0) {
                fivetuple = _ws_col_Protocol+ip_src+ip_dst+udp_srcport+udp_dstport;
            } else {
                fivetuple = _ws_col_Protocol+ip_src+ip_dst;
                // std::cerr << "NN "
                // << tcp_flags_syn << " " << tcp_flags_fin << " " << ip_src << " " 
                // << ip_dst << " " << tcp_srcport << " " << tcp_dstport << " " << udp_srcport << " " << udp_dstport << " "
                // << ip_proto << " " << ip_len << " " << _ws_col_Protocol << "\n";
                // break;
            }
            if(flowid.count(fivetuple)==0) {
                const auto tmp = flowid.size();
                flowid[fivetuple].id = tmp;
            }
            if(protoid.count(_ws_col_Protocol)==0) {
                const auto tmp = protoid.size();
                protoid[_ws_col_Protocol] = tmp;
            }
            flowid[fivetuple].count++;
            // ip len buckets
            if(ip_len < 48) {
                ip_len_bucket = 0;
            } else if(ip_len < 64) {
                ip_len_bucket = 1;
            } else if(ip_len < 1480) {
                ip_len_bucket = 2;
            } else {
                ip_len_bucket = 3;
            }
            ip_lens[ip_len_bucket]++;
            std::cout
                << reqcount++ << " "
                << flowid[fivetuple].id << " " << "50" << " "
                << protoid[_ws_col_Protocol] << " "
                << ip_len_bucket << " "
                << tcp_flags_syn << " "
                << tcp_flags_fin << "\n";
            // if(--limit<1) {
            //     break;
            // }

        }
        uint64_t singleton = 0;
        uint64_t repeat = 0;
        uint64_t total = 0;
        for(auto & it : flowid) {
            total+=it.second.count;
            if(it.second.count==1) {
                singleton++;
            } else {
                //            std::cerr << it.second.id << " " << it.second.count << "\n";
                repeat+=it.second.count;
            }
        }
        std::cerr << "summary " << argv[i] << " " << singleton << " " << repeat << " " << total << " uniqs " << flowid.size() << " ip_len ";
        for(auto & it: ip_lens) {
            std::cerr << it.first << "-" << it.second << " ";
        }
        std::cerr << "\n";
    }
}
