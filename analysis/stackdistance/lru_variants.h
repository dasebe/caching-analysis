#include <unordered_map>
#include <list>

typedef std::list<uint64_t>::iterator ListIteratorType;
typedef std::unordered_map<uint64_t, ListIteratorType> lruCacheMapType;

/*
  LRU: Least Recently Used eviction
*/
class LRUCache
{
protected:
    uint64_t _cacheSize;
    // list for recency order
    std::list<uint64_t> _cacheList;
    // map to find objects in list
    lruCacheMapType _cacheMap;

    virtual void hit(lruCacheMapType::const_iterator it);

public:
    LRUCache(uint64_t size)
        : _cacheSize(size)
    {
    }
    virtual ~LRUCache()
    {
    }

    virtual bool lookup(uint64_t req);
    virtual void admit(uint64_t req);
    virtual void evict();
};

