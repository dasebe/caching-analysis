#include "lib/csv.h"
#include <iostream>
#include <unordered_map>
#include <map>
#include <vector>
#include <iomanip>

int main(int argc, char *argv[]) {

    double unix_time;
    int tcp_flags_syn, tcp_flags_fin;
    std::string ip_src, ip_dst, _ws_col_Protocol;
    std::string tcp_srcport, tcp_dstport, udp_srcport, udp_dstport, ip_proto;
    uint64_t ip_len = 0;

    struct flow{
        uint64_t packet_count;
        double first_time_seen; // when flow appeared in unix_timestamp
        double last_time_seen; // when did we last see flow in unix_timestamp
        uint64_t first_seq; // first seen
        uint64_t last_seq; // in packets
        uint64_t total_bytes;
        bool is_tcp, had_syn;
        uint64_t fin_packets;
        //        std::vector<uint64_t> ia_times_unix;
        std::vector<uint64_t> ia_times_seq;
    };
    std::unordered_map<std::string, flow> flowid;
    std::string fivetuple;
    uint64_t reqcount = 0;

    for(int i=1; i<argc; i++) {
        io::CSVReader<12> reader(argv[i]);

        //    reader->set_header("ts", "app", "disk", "act" ,"offest","size","resptime");
        while(reader.read_row(unix_time,
                               tcp_flags_syn,tcp_flags_fin,ip_src,ip_dst,
                               tcp_srcport,tcp_dstport,udp_srcport,udp_dstport,
                               ip_proto,ip_len,_ws_col_Protocol)
              )
        {
            fivetuple.clear();
            if(_ws_col_Protocol.compare("TCP")==0) {
                fivetuple = _ws_col_Protocol+","+ip_src+","+ip_dst+","+tcp_srcport+","+tcp_dstport;
            } else if(_ws_col_Protocol.compare("UDP")==0) {
                fivetuple = _ws_col_Protocol+","+ip_src+","+ip_dst+","+udp_srcport+","+udp_dstport;
            } else {
                continue;
            }
            reqcount++;

            if(flowid.count(fivetuple)==0) { // we've never seen this before
                flowid[fivetuple].first_time_seen = unix_time;
                flowid[fivetuple].first_seq = reqcount;
                if(_ws_col_Protocol.compare("TCP")==0) {
                    flowid[fivetuple].is_tcp = true;
                    flowid[fivetuple].had_syn = (tcp_flags_syn == 1);
                }
            } else {
                // seen this flow before --- compute IA
                //                flowid[fivetuple].ia_times_unix.push_back(unix_time - flowid[fivetuple].last_time_seen);
                flowid[fivetuple].ia_times_seq.push_back(reqcount - flowid[fivetuple].last_seq);
            }
            flowid[fivetuple].packet_count++;
            flowid[fivetuple].last_time_seen = unix_time;
            flowid[fivetuple].last_seq = reqcount;
            flowid[fivetuple].total_bytes += ip_len;
            if(tcp_flags_fin==1) {
                flowid[fivetuple].fin_packets++;
            }
        }
    }

    // done with several csvs
    std::cout << std::setprecision(13);
    std::cout << "prot,ipsrc,ipdst,portsrc,portdst,bytes,packets,start_time,flowdur_sec,flowdur_packets,syn,fin,vectorsize,vector\n";
    const char* sep = "\t";
    for(auto fl: flowid) {
        if(fl.second.packet_count > 1000) {
            std::cout << fl.first
                      << sep << fl.second.total_bytes
                      << sep << fl.second.packet_count
                      << sep << fl.second.first_time_seen
                      << sep << fl.second.last_time_seen - fl.second.first_time_seen
                      << sep << fl.second.last_seq - fl.second.first_seq
                      << sep << fl.second.had_syn
                      << sep << fl.second.fin_packets;
            for(auto it: fl.second.ia_times_seq) {
                std::cout << sep << it;
            }
            std::cout << "\n";
        }
    }
}
