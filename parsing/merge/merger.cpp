#include <fstream>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <string>
 
using namespace std;

const size_t EXTRAFIELDS = 3;

struct traceLine {
    int64_t ts;
    uint64_t newId;
    string fields[EXTRAFIELDS+1];
    bool eof;
};
// parser tmps
string id;
int64_t t;
string extra[EXTRAFIELDS+1];
// rewrite id config
unordered_map<string, uint64_t> oldToNewId;
uint64_t nextNewId = 0;

void parseLine(ifstream * stream, traceLine & line, size_t idx) {
    if(stream->good() && !stream->eof()) {
        // ok we can parse
        ( (*stream) >> t >> id);
        // update current entry
        line.ts = t;
        string idHash = id + ":" + to_string(idx);
        if(oldToNewId.count(idHash)==0) {
            oldToNewId[idHash] = nextNewId++;
        }
        line.newId = oldToNewId[idHash];
        for(size_t j=0; j<EXTRAFIELDS+1; j++) {
            ( (*stream) >> extra[j]);
            line.fields[j] = extra[j];
        }
        // debug output
        // cerr << "traceid " << idx << " oldt " << t << " oldid " << id << " newid " << line.newId;
        // for(size_t j=0; j<EXTRAFIELDS+1; j++) {
        //     cerr << " " << extra[j];
		
        // }
        // cerr << "\n";

        // if eof, .. errors reduce count
        if(!stream->good() || stream->eof()) {
            line.eof = true;
        } else {
            line.eof = false;
        }
    }
}


int main (int argc, char* argv[])
{
    // output help if insufficient params
    if(argc < 2) {
        cerr << argv[0] << " outputFile [inputFiles]" << endl;
        return 1;
    }
    
    // trace properties
    const char* outputFile = argv[1];
    ofstream outfile(outputFile);

    cerr << "started, parsed " << outputFile << "\n";

    nextNewId = 0;

    vector<ifstream*> infiles;
    vector<traceLine> LastLines;
    for(int i=2; i<argc; i++) {
        cerr << "parsed " << argv[i] << "\n";
        infiles.push_back(new ifstream());
        infiles[i-2]->open(argv[i]);
        if(!infiles[i-2]->good() || infiles[i-2]->eof()) {
            cerr << "error opening " << argv[i] << "\n";
            return 1;
        }
        LastLines.push_back(traceLine());
    }


    //    uint64_t reqs = 0;
    int64_t firstTime;

    // initial parse of files
    // i = 2
    parseLine(infiles[2-2],LastLines[2-2],2-2);
    firstTime = LastLines[2-2].ts;
    // i = 3...
    for(int i=3; i<argc; i++) {
        parseLine(infiles[i-2],LastLines[i-2],i-2);
        if(LastLines[2-2].ts < firstTime) {
            firstTime = LastLines[2-2].ts; // save first and earliest timestamp
        }
    }

    while (true)
    {
        // which file has earliest timestamp
        int64_t nextTime;
        size_t nextIdx = 0;
        size_t activeTraces = 0;
        int i=2;
        // find the first non-eof trace to initialize
        for(; i<argc; i++) {
            if(LastLines[i-2].eof) {
                continue;
            }
            activeTraces++;
            nextTime = LastLines[i-2].ts;
            nextIdx = i-2;
            //cerr << "first " << nextTime << " " << nextIdx << "\n";
            break;
        }
        // find the lowest timestamp
        for(; i<argc; i++) {
            if(LastLines[i-2].eof) {
                continue;
            }
            activeTraces++;
            if(LastLines[i-2].ts < nextTime) {
                nextTime = LastLines[i-2].ts;
                nextIdx = i-2;
            }
        }
        //cerr << "lowest " << nextTime << " " << nextIdx << "\n";
        if(activeTraces==0) {
            //std::cerr << "no traces left\n";
            break;
        }
        // next output
        outfile << LastLines[nextIdx].ts - firstTime; //normalize to first time stamp
        outfile << " " << LastLines[nextIdx].newId;
        for(size_t j=0; j<EXTRAFIELDS+1; j++) {
            cerr << "nextIdx " << nextIdx << " outj " << j << " f " << LastLines[nextIdx].fields[j] << "\n";
            outfile << " " << LastLines[nextIdx].fields[j];
        }
        outfile << " " << nextIdx; // newfeature
        outfile << "\n";
        // parse outputted file
        parseLine(infiles[nextIdx],LastLines[nextIdx],nextIdx);

        // if(reqs++>100) {
        //     break;
        // }
    }

    cerr << "finishing up" << "\n";

    for(int i=2; i<argc; i++) {
        cerr << "closing " << argv[i] << "\n";      
        infiles[i-2]->close();
    }

    outfile.close();

    cerr << "done\n";

    return 0;
}
