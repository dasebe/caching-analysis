#include "lru_variants.h"

int64_t LRUList::touch(string key) {
    if (_objectNodeMap.count(key) == 0) {
        // first access to this object
        _objectNodeMap[key] = _lruTree.Insert(key);
        return INT64_MAX;
    } else {
        // lookup node, get rank, and update position
        auto node = _objectNodeMap[key];
        int64_t rank = node->Rank();
        _lruTree.Remove(node);
        _lruTree.InsertNode(node);
        return rank;
    }
}
