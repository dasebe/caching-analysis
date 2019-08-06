#include <fstream>
#include <iostream>
//#include <unordered_map>
#include <vector>
 
using namespace std;

const size_t EXTRAFIELDS = 3;

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
    struct traceLine {
      int64_t ts;
      string fields[EXTRAFIELDS+2];
    };
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


    string id;
    int64_t t, latestTime = 0;
    string extra[EXTRAFIELDS+2];
    bool allContinue = true;
    uint64_t reqs = 0;
    while (allContinue)
    {
      for(int i=2; i<argc; i++) {
	if(
	   LastLines[i-2].ts<0 // first line (maybe redundant)
	   || LastLines[i-2].ts<=latestTime // time has progressed beyond this line
	   ) {
	  ifstream * stream = infiles[i-2];
	  ( (*stream) >> t);
	  cerr << "s " << i << " " << t;
	  for(size_t j=0; j<EXTRAFIELDS+2; j++) {
	    ( (*stream) >> extra[j]);
	    cerr << " " << extra[j];
		
	  }
	  cerr << "\n";
	  allContinue &= stream->good();
	  allContinue &= !stream->eof();
	
	  LastLines[i-2].ts = t;
	  for(size_t j=0; j<EXTRAFIELDS+2; j++) {
	    LastLines[i-2].fields[j] = extra[j];
	  }
	}
      }
      
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
