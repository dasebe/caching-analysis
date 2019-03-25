#include <fstream>
#include <iostream>
#include <string>
#include <regex>
#include <math.h>

using namespace std;

int main (int argc, char* argv[])
{

  // trace properties
  const string path = argv[1];
  ifstream infile(path);
  std::cerr << "opened " << path << "\n";

  int tcp_flags_syn, tcp_flags_fin;
  string ip_src, ip_dst, _ws_col_Protocol;
  string tcp_srcport, tcp_dstport, udp_srcport, udp_dstport, ip_proto;
  string ip_len;
      
  int i = 30;

  string input;

  while (getline(infile, input))
  {
      stringstream ss(input);      
      ss >> tcp_flags_syn >> tcp_flags_fin
         >> ip_src >> ip_dst
         >> tcp_srcport >> tcp_dstport >> udp_srcport >> udp_dstport
         >> ip_proto >> ip_len
         >> _ws_col_Protocol;
        std::cerr
            << tcp_flags_syn << " " << tcp_flags_fin << " " << ip_src << " " 
            << ip_dst << " " << tcp_srcport << " " << tcp_dstport << " " << udp_srcport << " " << udp_dstport << " "
            << ip_proto << " " << ip_len << " " << _ws_col_Protocol << "\n";
        if(--i<1) {
            break;
        }
  }

  return 0;
}
