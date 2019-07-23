#include "lru_variants.h"

/*
  LRU: Least Recently Used eviction
*/
bool LRUCache::lookup(uint64_t req)
{
    auto it = _cacheMap.find(req);
    if (it != _cacheMap.end()) {
        hit(it);
        return true;
    }
    return false;
}

void LRUCache::admit(uint64_t req)
{
    // check eviction needed
    if (_cacheList.size() > _cacheSize) {
        evict();
    }
    // admit new object
    _cacheList.push_front(req);
    _cacheMap[req] = _cacheList.begin();
}

void LRUCache::evict()
{
    // evict least popular (i.e. last element)
    if (_cacheList.size() > 0 && _cacheMap.size() > 0) {
        ListIteratorType lit = _cacheList.end();
        lit--;
        uint64_t cand = *lit;
        _cacheMap.erase(cand);
        _cacheList.erase(lit);
    }
}

void LRUCache::hit(lruCacheMapType::const_iterator it)
{
    // list splice syntax to transfer a single element
    _cacheList.splice(_cacheList.begin(), _cacheList, it->second);
}

