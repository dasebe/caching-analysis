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
    if(argc < 3) {
    cerr << "usage:\n" << argv[0] << " outfile upload? infile1 infile2 ..\n";
    return 1;
  }
  cerr << "starting ..." << endl;

  const char* outputMem = argv[1];
  // upload flag means there'll be an additional column to parse
  bool upload = false;
  string uploadpar(argv[2]);
  if(uploadpar.compare("upload") == 0 || uploadpar.compare("1") == 0 || uploadpar.compare("yes") == 0) {
      upload = true;
      cerr << "upload trace\n";
  }
  ofstream outfile(outputMem);

  int64_t size, simpleId=0;
  string strid, timestamp, strtype;
  unordered_map<string,uint64_t> dSimpleId;
  unordered_map<string,size_t> typeId;
  const char row_delim = '\n';
  const char field_delim = '\t';
  string row;

  uint64_t requestCount = 0;

  for(int i = 3; i<argc; i++) {
      const char* inputFile = argv[i];
      cerr << "parsing trace " << i << " file " << inputFile << "\n";
      ifstream infile(inputFile);

      // ignore first line of headers
      getline(infile, row, row_delim);

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

          if(upload) {
              // get type
              getline(ss, field, field_delim);
              if(field.empty()) {
                  cerr << "empty type (id=" << strid << ")\n" << row << endl;
                  continue;
              }
              strtype = field;
              if(typeId.count(strtype)==0) {
                  // new type
                  const size_t idx = typeId.size();
                  typeId[strtype] = idx;
                  cerr << timestamp << " type " << strtype << " : " << typeId[strtype] << "\n";
              }
              field.clear();
          }

          // get size
          getline(ss, field, field_delim);
          if(field.empty()) {
              cerr << "empty size " << row << endl;
              continue;
          }
          stringstream fieldstream2( field );
          fieldstream2 >> size;
          field.clear();

          // ignore last field
          getline(ss, field, field_delim);

          // new id= origin_id + object_size + url_parameters
          if(dSimpleId.count(strid)==0)
              dSimpleId[strid]=simpleId++;

          // skip incomplete objects
          if (size <= 1)
              continue;

          requestCount++;
          outfile << timestamp << " " << dSimpleId[strid] << " " << size << " " << typeId[strtype] << "\n";
      }
      infile.close();
      cerr << "done with " << i << " file " << inputFile << " timestamp " << timestamp << " requests " << requestCount << " objects " << dSimpleId.size() << "\n";
  }
  outfile.close();

  cerr << "done" << endl;
  
  return 0;
}
