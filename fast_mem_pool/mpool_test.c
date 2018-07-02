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
    int i;
#define MAX_STRUCTS     4
    my_struct_t *myptr[MAX_STRUCTS]={0};
    my_struct_t *ptr;
    void *baseptr = malloc(sizeof(my_struct_t)*MAX_STRUCTS);

    MPOOL_INIT(CHN, baseptr, MAX_STRUCTS, my_struct_t);
    MPOOL_STATS("init", CHN);

    for(i=0;i<MAX_STRUCTS;i++)
    {
        MPOOL_ALLOC(CHN, myptr[i]);
        MPOOL_STATS("allocin", CHN);
        {
            MPOOL_DEALLOC(CHN, myptr[i]);
            MPOOL_STATS("deallocin", CHN);
        }
    }
    MPOOL_ALLOC(CHN, ptr);
    MPOOL_STATS("alloc", CHN);

    MPOOL_DEALLOC(CHN, ptr);
    MPOOL_STATS("dealloc", CHN);
    MPOOL_ALLOC(CHN, myptr[0]);
    MPOOL_STATS("alloc", CHN);

    MPOOL_DEINIT(CHN);
    return 0;
}
