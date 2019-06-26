#include <fstream>
#include <iostream>
#include <string>
#include <random>
#include <unordered_map>
#include <math.h>
 
using namespace std;

// sample down and then up again, by duplicating objects
// this should create a comparable trace
// - need to rename object ids

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 4) {
        cerr << argv[0] << " inputFile outputFile sampleFactor" << endl;
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];
    const char* outputFile = argv[2];
    const double sampleFactor  = std::stod(argv[3]);
    const int64_t upScale = int64_t(round(1.0/sampleFactor));

    ifstream infile(inputFile);
    ofstream outfile(outputFile);

    cerr<< "started "
        << inputFile << " "
        << outputFile << " "
        << sampleFactor << " upscale by "
        << upScale << "\n";
    
    random_device rd;
    mt19937 gen(rd());
    bernoulli_distribution sampledecision(sampleFactor);

    uint64_t sampled_objs = 0, sampled_reqs = 0, total_reqs = 0;
    unordered_map<int64_t, bool> samplethisobject;
    unordered_map<int64_t, int64_t> newObjectId;
    int64_t objectIdCounter = 0;

    int64_t t, id, size, tmp;
    while (infile >> t >> id >> size >> tmp)
    {
        total_reqs++;
        if(samplethisobject.count(id)==0) {
            // new object to be decided
            const bool curdecision= sampledecision(gen);
            samplethisobject[id] = curdecision;
            sampled_objs += curdecision;
            // record new object id
            newObjectId[id] = objectIdCounter;
            objectIdCounter+= upScale; // add space for upscaling IDs
        } else {
            if(samplethisobject[id]) {
                // known object, which should be sampled
                for(int64_t oid=newObjectId[id]; oid<newObjectId[id]+upScale; oid++) {
                    sampled_reqs++;
                    outfile << t << " " << oid << " " << size << " " << tmp << "\n";
                }
            }
        }
    }

    infile.close();
    outfile.close();

    cout
        << inputFile << " "
        << sampleFactor << " "
        << sampled_objs/double(samplethisobject.size()) << " "
        << sampled_reqs/double(total_reqs) << "\n";

    return 0;
}
