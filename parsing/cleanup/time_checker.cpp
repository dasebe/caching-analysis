#include <fstream>
#include <iostream>

using namespace std;
 
int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc != 2) {
        cerr << argv[0] << " inputFile" << endl;
        cerr << "given " << argc << " expected " << 2 << "\n";
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];

    ifstream infile(inputFile);

    cerr<< "started "
        << inputFile << "\n";
    
    int64_t newt=0, lastT=0;
    std::string id;
    int64_t t, size, tmp;
    while (infile >> t >> id >> size >> tmp)
    {
        if(size==0) {
            continue;
        }
        // check time
        if(lastT==0) {
            lastT = t;
        }
        if(t>=lastT) {
            newt += (t-lastT);
            lastT = t;
        } else {
            cerr << inputFile << " time-inconsistency " << lastT << " " << t << "\n";
            break;
        }
    }

    infile.close();

    return 0;
}
