#include <unordered_map>
#include "ranktree/rank-tree.h"

class LRUList
{
protected:
    RankTree _lruTree;
    unordered_map<string, RankTreeNode*> _objectNodeMap;

public:
    LRUList()
    {
    }
    int64_t touch(std::string key);
};

