#include <fstream>
#include <iostream>
#include <string>
#include <chrono>

using namespace std;

uint64_t cache_sim(uint64_t id, uint64_t size) {
    auto r = id+size;
    return r;
}

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 2) {
        cerr << "test inputFile" << endl;
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];
    ifstream infile;
    // Increase buffer size
    char buffer[16184];
    infile.rdbuf()->pubsetbuf(buffer, 16184);
    infile.open (inputFile, std::ifstream::in);
    // parsing
    int64_t t, id, size, tmp;

    uint64_t reqcount = 0;
    auto t_start = std::chrono::high_resolution_clock::now();

        
    while (infile >> t >> id >> size >> tmp)
    {
        reqcount++;
        cache_sim(id, size);
        if(reqcount > 10000000) {
            auto t_end = std::chrono::high_resolution_clock::now();
            auto dur_ms = std::chrono::duration<double, std::milli>(t_end-t_start).count();
            cout << reqcount / (dur_ms/1000.0) << "\n";
            reqcount = 0;
            t_start = std::chrono::high_resolution_clock::now();
        }
    }

    infile.close();

    return 0;
}
