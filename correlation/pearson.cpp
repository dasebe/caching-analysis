#include <cmath>
#include <cstdio>
#include <cassert>
#include <vector>
#include <iostream>
#include <algorithm>
#include <iomanip>
#include <fstream>
#include <string>
#include <unordered_map>
#include <map>
using namespace std;

double sum(vector<double> * a)
{
    double s = 0;
    for (size_t i = 0; i < a->size(); i++)
    {
        s += (*a)[i];
    }
    return s;
}

double mean(vector<double> * a)
{
    if(a->size()==0) {
        std::cerr <<  " ERROR 0 stddevs \n";
    }
    return sum(a) / a->size();
}

double sqsum(vector<double> * a)
{
    double s = 0;
    for (size_t i = 0; i < a->size(); i++)
    {
        s += (*a)[i]  *  (*a)[i];
    }
    return s;
}

double stdev(vector<double> * nums)
{
    double N = nums->size();
    if(N==0) {
        std::cerr <<  " ERROR 0 N \n";
    }
    auto part1 = sqsum(nums) / N;
    auto part2 = sum(nums) / N;
    auto part2sq = part2*part2;
    if(part1==part2sq) {
        std::cerr <<  " ERROR equal sums " << part1 << " " << part2 << "\n";
        for(size_t i=0; i<N; i++) {
            if((*nums)[i] != 0) {
                std::cerr <<  (*nums)[i] << "\n";
            }
        }
        assert(part1!=part2sq);
    }
    return pow(part1 - part2sq, 0.5);
}

vector<double> * VMinus(vector<double> * a, double b)
{
    vector<double> * retvect = new vector<double>();
    for (size_t i = 0; i < a->size(); i++)
    {
        retvect->push_back((*a)[i] - b);
    }
    return retvect;
}

vector<double> * VProd(vector<double> * a, vector<double> * b)
{
    vector<double> * retvect = new vector<double>();
    for (size_t i = 0; i < a->size() ; i++)
    {
        retvect->push_back((*a)[i] * (*b)[i]);
    }
    return retvect;
}

double pearsoncoeff(vector<double> * X, vector<double> * Y)
{
    auto minus1 = VMinus(X,mean(X));
    auto minus2 = VMinus(Y,mean(Y));
    auto prod1 = VProd(minus1,minus2);
    delete minus1;
    delete minus2;
    auto sumprod = sum(prod1);
    auto stddevs = X->size()*stdev(X)* stdev(Y);
    if(stddevs==0) {
        std::cerr <<  " ERROR 0 stddevs " << X->size() << " " << stdev(X) << " " << stdev(Y) << "\n";
    }
    double pearson = sumprod / stddevs;
    delete prod1;
    return pearson;
}

int main (int argc, char* argv[]) {

    // trace properties
    const char* path = argv[1];
    const uint64_t initCount  = std::stoull(argv[2]);
    const uint64_t interval  = std::stoull(argv[3]); // interval length
    const uint64_t reps  = std::stoull(argv[4]); // how many intervals
    const uint64_t objCount  = std::stoull(argv[5]);

    std::cerr << "path " << path << " initCount " << initCount << " interval " << interval << " reps " << reps << " objCount " << objCount << "\n";

    ifstream infile;
    infile.open(path);
    
    uint64_t reqCount = 0;
    unordered_map<uint64_t,uint64_t> freqs;
    uint64_t t, id;
    uint64_t size;
    while (infile >> t >> id >> size) {
        reqCount++;
        if(reqCount > initCount) {
            break;
        }
        freqs[id]++;
    }
    
    cerr << "reqs1 " << reqCount << "\n";
    reqCount= 0;
    infile.close();
    infile.open(path);

    map<uint64_t,uint64_t> freqsOrdered;
    for(auto & it: freqs) {
        freqsOrdered[it.second] = it.first;
    }

    unordered_map<uint64_t, vector<double> * > vecs;

    /// select which ids to track

    auto fit = freqsOrdered.rbegin();
    for(size_t i=0; i<=objCount; i++) {
        const uint64_t id=fit->second;
        if(freqs[id]>10) {
            vecs[id] = new vector<double>();
            vecs[id]->push_back(0);
            //            cerr << fit->second << " " << fit->first << "\n";
        } else {
            cerr << "excluding " << fit->second << " " << fit->first << "\n";
        }
        fit++;
    }

    uint64_t i = 0;
    uint64_t index = 0;

    // track ids and create vector of counts over time

    freqs.clear();
    vector<double> * vecptr;
    while (infile >> t >> id >> size) {
        reqCount++;
        if(vecs.count(id) > 0) {
            vecptr = vecs[id];
            (*vecptr)[index]++;
            freqs[id]++;
        }
        if(i++ > interval) {
            if(index++ > reps) {
                break;
            }
            i = 0;
            for(auto & vic: vecs) {
                vic.second->push_back(0);
            }
        }
    }
    cerr << "reqs2 " << reqCount << " reps " << index << "\n";

    // check counts
    // freqsOrdered.clear();
    // for(auto & it: freqs) {
    //     freqsOrdered[it.second] = it.first;
    // }
    // for(auto it= freqsOrdered.rbegin(); it!=freqsOrdered.rend(); it++) {
    //     cerr << it->second << " " << it->first << "\n";
    // }


    // calculate
    auto vic = vecs.begin();
    cout << fixed << setprecision(6);
    i = 0;
    do {
        vecptr = vic->second;
        auto lag1 = vic;
        int j=i+1;
        while(++lag1 != vecs.end()) {
            vector<double> * vecptr2 = lag1->second;
            cout << path << " " << initCount << " "
                 << interval << " " << reps << " " << objCount
                 << " i " << i << " j " << j << " p "
                 << pearsoncoeff(vecptr,vecptr2) << endl;
            j++;
        }
        i++;
    } while(++vic != vecs.end());

    for(auto & vic: vecs) {
        delete vic.second;
    }

    return 0;
}
