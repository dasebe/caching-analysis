#!/bin/bash

#  const char* path = argv[1];
#  const uint64_t initCount  = std::stoull(argv[2]);
#  const uint64_t interval  = std::stoull(argv[3]); // interval length
#  const uint64_t reps  = std::stoull(argv[4]); // how many intervals
#  const uint64_t objCount  = std::stoull(argv[5]);
#  const uint64_t skipcols  = std::stoull(argv[6]);


for obj in 10000 100000 1000000; do
    for reps in 10000 20000; do
	for i in "msr_big.tr 10000000 $reps 10000 $obj 2" "anonymous.tr 10000000 $reps 10000 $obj 1" "caida_cache.tr 10000000 $reps 10000 $obj 4" "wc200m.tr 10000000 $reps 10000 $obj 1"; do
	    echo "./pearson /scratch2/traces/$i"
	done
    done
done  | parallel -j 4 --tmpdir /home/dberger/tmp > pearson.log
