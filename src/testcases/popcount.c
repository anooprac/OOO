#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint64_t n = 0xFACEDEADFEEDBEEF;
    n = (n & 0x5555555555555555ull) + ((n >> 1) & 0x5555555555555555ull);
    n = (n & 0x3333333333333333ull) + ((n >> 2) & 0x3333333333333333ull);
    n = (n & 0x0f0f0f0f0f0f0f0full) + ((n >> 4) & 0x0f0f0f0f0f0f0f0full);
    n = (n & 0x00ff00ff00ff00ffull) + ((n >> 8) & 0x00ff00ff00ff00ffull);
    n = (n & 0x0000ffff0000ffffull) + ((n >>16) & 0x0000ffff0000ffffull);
    n = (n & 0x00000000ffffffffull) + ((n >>32) & 0x00000000ffffffffull);
    printf("%lld\n", n); 
    return n;
}
