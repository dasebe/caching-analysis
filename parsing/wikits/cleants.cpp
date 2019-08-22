#include <fstream>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <string>
 
using namespace std;


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

    

    return 0;
}
