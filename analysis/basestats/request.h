#pragma once

#include <vector>

struct Request {
    double ts; //normalized to seconds
    std::string oid;
    int64_t size; //bytes

    Request(double nts, std::string noid, int64_t nsize)
        : ts(nts), oid(noid), size(nsize)
    {
    }
};
typedef std::vector<Request> ReqBatch;
