#include <fstream>
#include <iostream>
#include <string>
#include <random>
 
using namespace std;

int main (int argc, char* argv[])
{

    // output help if insufficient params
    if(argc < 4) {
        cerr << "webcachesim inputFile outputFile sampleFactor" << endl;
        return 1;
    }

    // trace properties
    const char* inputFile = argv[1];
    const char* outputFile = argv[2];
    const double sampleFactor  = std::stod(argv[3]);

    ifstream infile(inputFile);
    ofstream outfile(outputFile);

    std::random_device rd;
    std::mt19937 gen(rd());
    std::bernoulli_distribution d(sampleFactor);

    int64_t t, id, size, tmp;
    while (infile >> t >> id >> size >> tmp)
    {
        cout << d(gen) << "\n";
    }

    infile.close();

    return 0;
}
