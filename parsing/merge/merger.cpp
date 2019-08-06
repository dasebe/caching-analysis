#include <fstream>
#include <iostream>
//#include <unordered_map>
#include <vector>
 
using namespace std;

const size_t EXTRAFIELDS = 3;

struct traceLine {
    int64_t ts;
    string fields[EXTRAFIELDS+2];
    int64_t newT;
    bool eof;
};
// parser tmps
string id;
int64_t t;
string extra[EXTRAFIELDS+2];

void parseLine(ifstream * stream, traceLine & line) {
    if(stream->good() && !stream->eof()) {
        // ok we can parse
        ( (*stream) >> t);
        cerr << "pp " << t;
        for(size_t j=0; j<EXTRAFIELDS+2; j++) {
            ( (*stream) >> extra[j]);
            cerr << " " << extra[j];
		
        }
        cerr << "\n";
        // update current entry
        line.newT += t - line.ts; // different between current and prev t
        line.ts = t;
        for(size_t j=0; j<EXTRAFIELDS+2; j++) {
            line.fields[j] = extra[j];
        }
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
        LastLines[i-2].newT = 0;
    }


    uint64_t reqs = 0;

    // initial parse of files
    for(int i=2; i<argc; i++) {
        parseLine(infiles[i-2],LastLines[i-2]);
    }

    while (true)
    {
        // which file has earliest timestamp
        int64_t nextTime = LastLines[0].ts;
        size_t nextIdx = 0;
        size_t activeTraces = 0;
        for(int i=2; i<argc; i++) {
            if(LastLines[i-2].eof) {
                continue;
            } else {
                activeTraces++;
            }
            if(LastLines[i-2].ts < nextTime) {
                nextTime = LastLines[i-2].ts;
                nextIdx = i-2;
            }
        }
        if(activeTraces==0) {
            std::cerr << "no traces left\n";
            break;
        }
        // next output
        outfile << LastLines[nextIdx].newT;
        for(size_t j=0; j<EXTRAFIELDS+2; j++) {
            outfile << " " << LastLines[nextIdx].fields[j];
        }
        outfile << "\n";
        // parse outputted file
        parseLine(infiles[nextIdx],LastLines[nextIdx]);

        if(reqs++>10) {
            break;
        }
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
