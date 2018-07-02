#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "mpool.h"

typedef struct _my_struct_
{
    int x, y, z;
    char a, b, c;
    uint32_t mpool_p;
}my_struct_t;

MPOOL_DEF(CHN);
int main(void)
{
    my_struct_t *myptr=NULL;
#define MAX_STRUCTS     4
    void *ptr = malloc(sizeof(my_struct_t)*MAX_STRUCTS);

    MPOOL_INIT(CHN, ptr, MAX_STRUCTS, my_struct_t);
    MPOOL_STATS("init", CHN);
    MPOOL_ALLOC(CHN, myptr);
    MPOOL_STATS("alloc", CHN);
    MPOOL_ALLOC(CHN, myptr);
    MPOOL_STATS("alloc", CHN);
    MPOOL_DEALLOC(CHN, myptr);
    MPOOL_STATS("dealloc", CHN);
    MPOOL_ALLOC(CHN, myptr);
    MPOOL_STATS("alloc", CHN);

    MPOOL_DEINIT(CHN);
    return 0;
}
