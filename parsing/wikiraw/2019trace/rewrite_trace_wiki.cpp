#include <fstream>
#include <unordered_map>
#include <string>
#include <sstream>
#include <unordered_map>
#include<iostream>

using namespace std;

int main (int argc, char* argv[])
{

  // parameters
  if(argc != 3) {
    cerr << "usage:\n" << argv[0] << " infile outfile\n";
    return 1;
  }

  const char* inputFile = argv[1];
  const char* outputMem = argv[2];

  cerr << "starting ..." << endl;

  ifstream infile(inputFile);
  ofstream outfile(outputMem);
  int64_t size, simpleId=0;
  string strid, timestamp;
  unordered_map<string,uint64_t> dSimpleId;

  const char row_delim = '\n';
  const char field_delim = '\t';
  string row;

  getline(infile, row, row_delim); // headers

  for (; getline(infile, row, row_delim); ) {
    // parse row
    istringstream ss(row);
    string field;

    // get timestamp
    getline(ss, field, field_delim);
    if(field.empty()) {
      cerr << "empty timestamp " << row << endl;
      continue;
    }
    timestamp = field;
    field.clear();

    // get ID
    getline(ss, field, field_delim);
    if(field.empty()) {
      cerr << "empty id " << row << endl;
      continue;
    }
    strid = field;
    field.clear();

    // get size
    field.clear();
    getline(ss, field, field_delim);
    if(field.empty()) {
      cerr << "empty size " << row << endl;
      continue;
    }
    stringstream fieldstream2( field );
    fieldstream2 >> size;

    // new id= origin_id + object_size + url_parameters
    if(dSimpleId.count(strid)==0)
      dSimpleId[strid]=simpleId++;

    // skip incomplete objects
    if (size <= 1)
      continue;

    outfile << timestamp << " " << dSimpleId[strid] << " " << size << "\n";
  }
  infile.close();
  outfile.close();

  cerr << "done" << endl;

  return 0;
}
