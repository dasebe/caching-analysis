// compile with: g++ -o lrusim -Wall -std=c++1y lrusim.cc
#include <cstddef>
#include <stdexcept>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <random>
#include <list>
#include <iomanip>
#include <vector>

using namespace std;

typedef tuple<long double, int, int> fi_pair_t;
typedef list<fi_pair_t>::iterator list_iterator_t;

int main (int argc, char* argv[])
{
    // parameters
    if(argc!=4) {
        cout << "\n inputfile outputfile maxtime\n";
        return 1;
    }
    const string inputfile(argv[1]);
    const string outputfile(argv[2]);
    const long double maxTime = std::stold(argv[3]);

    ifstream infile;
    infile.open(inputfile);
    random_device rd;
    mt19937 rnd_gen (rd ());
    int64_t tsize;
    long double trate = 1e12;
    list<fi_pair_t> reqseq;
    vector<long> size;
    long i=0;

    std::uniform_real_distribution<double> uniform(0.0,maxTime);

    while(infile >> tsize) {
        if(tsize<1 || tsize > 4096) {
            continue;
        }
        cerr << trate << "\n";
        size.push_back(tsize);
        exponential_distribution<> iaRandH (trate);
        long double globalTime = iaRandH(rnd_gen);
        if(globalTime>maxTime) {
            // treat as one-hit-wonder
            globalTime = uniform(rnd_gen);
            //            cerr << globalTime << " " << i << "\n";
            reqseq.push_back(fi_pair_t(globalTime,i,0));
        } else {
            while(globalTime<maxTime) {
                reqseq.push_back(fi_pair_t(globalTime,i,0));
                globalTime += iaRandH(rnd_gen);
            }
        }
        i++; //that's the "id"
        trate /= 1.5;
    }
    infile.close();

    // sort tuples lexicographically, i.e., by time
    cout << "finished raw req sequence.\n";
    reqseq.sort();
    cout << "finished sorting req.\n";

    ofstream outfile;
    outfile.open(outputfile);
    outfile<<fixed<<setprecision(0); // turn of scientific notation

    // output request sequence
    list_iterator_t rit;
    for (rit=reqseq.begin(); rit != reqseq.end(); ++rit) {
        outfile << 1000*get<0>(*rit) << " " << get<1>(*rit) << " " << size[get<1>(*rit)] << "\n"; 
    }

    cout << "finished output.\n";
    outfile.close();

    return 0;
}
