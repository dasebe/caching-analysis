#include <string>
#include <iostream>
#include <fstream>
#include <unordered_map>
#include <vector>
#include <math.h>
using namespace std;

struct entry {
    uint64_t t;
    uint64_t id;
    uint64_t size;
    uint64_t dvar;

    entry(uint64_t nt, uint64_t nid, uint64_t nsize, uint64_t ndvar)
        : t(nt), id(nid), size(nsize), dvar(ndvar)
    {}
} ;

// main
int main(int argc, char* argv[])
{
    vector<ifstream*> files;
    for(int i=1; i<argc; i++) {
        ifstream * tmp = new ifstream(argv[i]);
        files.push_back(tmp);
    }

    vector<entry> curLines;

    uint64_t t, id, size, hitsum = 0, reqsum = 0, sizesum = 0;
    long double util, dvar, hit;

    // I/O ifstream speed up trick
    setlocale(LC_ALL, "C");

    for(auto it: files) {
        curLines.push_back(entry(0,0,0,0));
    }

    unordered_map<uint64_t, uint64_t> diffDist;

    uint64_t iterCounter = 0, skipCounter = 0;

    bool endOfAnyFile = false;
    while(!endOfAnyFile) {
        iterCounter++;

        for(int i=1; i<argc; i++) {
            if(files[i-1]->eof() ) {
                endOfAnyFile = true;
                goto exitloop;
            }
            *files[i-1] >> t >> id >> size >> util >> dvar >> hit;
            curLines[i-1].t = t;
            curLines[i-1].id = id;
            curLines[i-1].size = size;
            curLines[i-1].dvar = dvar;
            skipCounter++;
        }

        uint64_t maxTime = curLines[0].t;
        for(int i=1; i<argc; i++) {
            if(curLines[i-1].t > maxTime)
                maxTime = curLines[i-1].t;
        }

        for(int i=1; i<argc; i++) {
            while(curLines[i-1].t < maxTime) {
                *files[i-1] >> t >> id >> size >> util >> dvar >> hit;
                if(files[i-1]->eof() ) {
                    endOfAnyFile = true;
                    goto exitloop;
                }
                curLines[i-1].t = t;
                curLines[i-1].id = id;
                curLines[i-1].size = size;
                curLines[i-1].dvar = dvar;
                //                cerr << "skipping mT " << maxTime << " t " << curLines[i-1].t << " i " << i << "\n";
            }
        }

        long double commonDvar = curLines[0].dvar;
        short lineSameCount = 0;
        for(int i=1; i<argc; i++) {
            if(curLines[i-1].dvar == commonDvar) {
                lineSameCount++;
            }
            else {
                //                cerr << "difference " << curLines[i-1].t << " i " << i << " cD " << commonDvar << " tD " << curLines[i-1].dvar << "\n";
            }
        }

        diffDist[files.size()-lineSameCount]++;
    }
 exitloop:
    cerr << "done\n";
    for(auto it: diffDist)
        cout << it.first << " " << it.second << endl;
    cout << "skip " << skipCounter << endl;
    cout << "iter " << iterCounter << endl;

    return 0;
}
