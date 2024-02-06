#pragma once

// ------------------- xxhash ------------------- //
#define XXH_STATIC_LINKING_ONLY /* access advanced declarations */
#define XXH_IMPLEMENTATION      /* access definitions */
#define XXH_INLINE_ALL          /* make all functions inline -- improvements of 200%! */

#include "xxhash.h"

// --------------- hard-coded mods --------------- //
#define MOD_29      ((1UL<<29)-1)
#define MOD_PRIME   1073741651
#define MOD_LPRIME  2861333663

#define SEED        426942

/*
#define REDUCE(key,mod,h)           \
    switch(mod) {                   \
        case MOD_29:                \
            h = key % MOD_29;       \
            break;                  \
        case MOD_PRIME:             \
            h = key % MOD_PRIME;    \
            break;                  \
        case MOD_LPRIME:            \
            h = key % MOD_LPRIME;   \
            break;                  \
        default:                    \
            h = key % mod;          \
    }                               \
*/
