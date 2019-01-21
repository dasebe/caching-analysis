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
  int64_t size, t=0, simpleId=0;
  string strid, urlpars, strtype;
  unordered_map<string,uint64_t> dSimpleId;
  unordered_map<string,size_t> typeId;

  const char row_delim = '\n';
  const char field_delim = '\t';
  string row;

  getline(infile, row, row_delim);

  for (; getline(infile, row, row_delim); ) {
    // parse row
    istringstream ss(row);
    string field;
    getline(ss, field, field_delim);
    // get ID
    if(field.empty()) {
      cerr << "empty id " << row << endl;
      continue;
    }
    strid = field;
    // url field
    field.clear();
    getline(ss, field, field_delim);
    urlpars = field;
    
    // get type
    field.clear();
    getline(ss, field, field_delim);
    if(field.empty()) {
      cerr << "empty type (id=" << strid << ")\n" << row << endl;
      continue;
    }
    strtype = field;
    if(typeId.count(strtype)==0) {
      // new type
      typeId[strtype]=typeId.size();
      cerr << t << " type " << strtype << " : " << typeId[strtype] << "\n";
    }

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
    if(dSimpleId.count(strid+field+urlpars)==0)
      dSimpleId[strid+field+urlpars]=simpleId++;

    // skip incomplete objects
    if (size <= 1)
      continue;

    outfile << t << " " << dSimpleId[strid+field+urlpars] << " " << size << " " << typeId[strtype] << endl;
    t++;    
  }
  infile.close();

  cerr << "rewrote " << t << " requests" << endl;

  return 0;
}
