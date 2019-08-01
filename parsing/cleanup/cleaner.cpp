#include <fstream>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <chrono>
 
using namespace std;

struct CacheObject
{
    std::string id;
    uint64_t size;

    CacheObject(std::string i, uint64_t s)
        : id(i), size(s)
    {
    }
        
    bool operator==(const CacheObject &rhs) const {
        return (rhs.id == id) && (rhs.size == size);
    }
};

// forward definition of extendable hash
template <class T>
void hash_combine(std::size_t & seed, const T & v);

// definition of a hash function on CacheObjects
// required to use unordered_map<CacheObject, >
namespace std
{
    template<> struct hash<CacheObject>
    {
        inline size_t operator()(const CacheObject cobj) const
        {
            size_t seed = 0;
            hash_combine<std::string>(seed, cobj.id);
            hash_combine<uint64_t>(seed, cobj.size);
            return seed;
        }
    };
}

// hash_combine derived from boost/functional/hash/hash.hpp:212
// Copyright 2005-2014 Daniel James.
// Distributed under the Boost Software License, Version 1.0.
// (See http://www.boost.org/LICENSE_1_0.txt)
template <class T>
inline void hash_combine(std::size_t & seed, const T & v)
{
    std::hash<T> hasher;
    seed ^= hasher(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}

 
int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 3) {
        cerr << argv[0] << " inputFile outputFile" << endl;
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];
    const char* outputFile = argv[2];

    ifstream infile(inputFile);
    ofstream outfile(outputFile);

    cerr<< "started "
        << inputFile << " "
        << outputFile << "\n";
    
    int64_t newt=0, lastT=0;
    uint64_t idcount = 0;
    unordered_map<CacheObject, std::vector<int64_t> > newid;
    std::string id;
    int64_t t, size, tmp;
    int64_t largeCounter = 0, fractionCounter = 0, reqCounter = 0, sizeZeroCounter = 0;
    while (infile >> t >> id >> size >> tmp)
    {
        if(size==0) {
            sizeZeroCounter++;
            continue;
        }
        if(tmp==0) {
            tmp=size;
        }
        CacheObject obj(id, size);
        if(newid.count(obj)==0) {
            newid[obj].push_back(idcount++);
        }
        if(size>1073741824) {
            // larger than 1GB
            largeCounter++;
            while(size>1073741824) {
                // create new id
                newid[obj].push_back(idcount++);
                size -= 1073741824;
            }
            // remainder
            newid[obj].push_back(idcount++);
        }
        if(tmp<size) {
            fractionCounter++;
        }
        reqCounter++;
    }

    std::cerr << inputFile << " reqs " << reqCounter << " large " << largeCounter << " fraction " << fractionCounter << " zeros " << sizeZeroCounter << "\n";
    // reset file
    infile.clear();
    infile.seekg(0, ios::beg);

    while (infile >> t >> id >> size >> tmp)
    {
        if(size==0) {
            continue;
        }
        if(tmp==0) {
            tmp=size;
        }
        // parse time stamp
        time_t time(t);
        struct tm *tmp2 = gmtime(&time);
        auto thour = tmp2->tm_hour;
        auto twday = tmp2->tm_wday;

        // create index
        CacheObject obj(id, size);
        // rewrite time
        if(lastT==0) {
            lastT = t;
        }
        if(t>lastT) {
            newt += (t-lastT);
            lastT = t;
        } else {
            cerr << "time inconsistency " << lastT << " " << t << "\n";
        }
        if(size>1073741824) {
            size_t ididx = 0;
            // larger than 1GB
            while(size>1073741824) {
                outfile << newt << " " << (newid[obj])[ididx] << " " << 1073741824 << " " << 1073741824/65536 << " " << thour << " " << twday << "\n";
                ididx++;
                size -= 1073741824;
                if(tmp>1073741824) {
                    tmp -= 1073741824;
                }
            }
            outfile << newt << " " << (newid[obj])[ididx] << " " << size << " " << tmp/65536 << " " << thour << " " << twday << "\n";
            //            std::cerr << "lf " << newt << " " << (newid[obj])[ididx] << "\n";
        } else {
            outfile << newt << " " << (newid[obj])[0] << " " << size << " " << tmp/65536 << " " << thour << " " << twday << "\n";
        }
    }


    infile.close();
    outfile.close();

    return 0;
}
