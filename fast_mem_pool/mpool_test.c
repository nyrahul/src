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

mpool_t chn;
int main(void)
{
    int i;
#define MAX_STRUCTS     4
    my_struct_t *myptr[MAX_STRUCTS]={0};
    my_struct_t *ptr;
    void *baseptr = malloc(sizeof(my_struct_t)*MAX_STRUCTS);

    mpool_init(&chn, baseptr, MAX_STRUCTS, 
            sizeof(my_struct_t), offsetof(my_struct_t, mpool_p));
    mpool_info(&chn, "init");

    for(i=0;i<MAX_STRUCTS;i++)
    {
        myptr[i] = mpool_alloc(&chn);
        mpool_info(&chn, "allocin");
        {
            mpool_dealloc(&chn, myptr[i]);
            mpool_info(&chn, "deallocin");
        }
    }
    ptr = mpool_alloc(&chn);
    mpool_info(&chn, "alloc");

    mpool_dealloc(&chn, ptr);
    mpool_info(&chn, "dealloc");
    myptr[0] = mpool_alloc(&chn);
    mpool_info(&chn, "alloc");

    mpool_deinit(&chn);
    return 0;
}
