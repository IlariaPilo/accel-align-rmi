#!/bin/bash

echo -e "Printing average running times for $1!\n"

cat $1 | grep "Time to align:" | awk '{ sum += $4 } END { avg = sum / NR; printf("Time to align: %.3f s\n", avg) }'
echo Breakdown:
cat $1 | grep "Input IO" | awk '{ sum += $4 } END { avg = sum / NR; printf("Input IO time: %.3f s\n", avg) }'
cat $1 | grep "Parse" | awk '{ sum += $3 } END { avg = sum / NR; printf("Parse time: %.3f s\n", avg) }'
cat $1 | grep "Seeding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Seeding time: %.3f s\n", avg) }'
# Seeding breakdown
cat $1 | grep "lookup keyv" | awk '{ sum += $4 } END { avg = sum / NR; printf("\tLookup keyv time: %.3f s\n", avg) }'
cat $1 | grep "lookup posv" | awk '{ sum += $4 } END { avg = sum / NR; printf("\tLookup posv time: %.3f s\n", avg) }'
cat $1 | grep "Hit count" | awk '{ sum += $4 } END { avg = sum / NR; printf("\tHit count time: %.3f s\n", avg) }'
cat $1 | grep "Swap high cov" | awk '{ sum += $5 } END { avg = sum / NR; printf("\tSwap high cov time: %.3f s\n", avg) }'
cat $1 | grep "Vpair build" | awk '{ sum += $6 } END { avg = sum / NR; printf("\tVpair build time [only for pe]: %.3f s\n", avg) }'
# embedding
cat $1 | grep "Embedding" | awk '{ sum += $3 } END { avg = sum / NR; printf("Embedding time: %.3f s\n", avg) }'
# extending
cat $1 | grep "Extending" | awk '{ sum += $9 } END { avg = sum / NR; printf("Extending time: %.3f s\n", avg) }'
# mark best region
cat $1 | grep "Mark best region" | awk '{ sum += $5 } END { avg = sum / NR; printf("Mark best region time: %.3f s\n", avg) }'
# output
cat $1 | grep "SAM" | awk '{ sum += $5 } END { avg = sum / NR; printf("SAM output time: %.3f s\n", avg) }'
