#pragma once

/* ----------[Fast fixed-size memory pool]-------------
Ref: http://www.thinkmind.org/download.php?articleid=computation_tools_2012_1_10_80006
*/

#ifndef offsetof
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#endif

typedef struct _fast_mpool_
{
    uint32_t    numOfBlks,  //Total number of blocks
                blkSz,      //Size of the user-supplied block structure
                numInited,  //Number of blocks whose mpool index is initialized
                numFreeBlks,//Number of Free blocks
                poff;       //Offset of index in user-supplied block structure
    uint8_t     *start,     //Start pointer of the storage
                *next;      //Next pointer of the storage
}mpool_t;

static inline void mpool_init(mpool_t *mp, uint8_t *bptr,
        uint32_t numBlks, uint32_t blksz)
{
    mp->numInited   = 0;
    mp->numFreeBlks = numBlks;
    mp->blkSz       = blksz;
    mp->numOfBlks   = numBlks;
    mp->start       = bptr;
    mp->next        = mp->start;
}

#define ADDR_FROM_INDEX(MP, I)  ((MP)->start + ((I) * (MP)->blkSz))
#define IDX_FROM_ADDR(MP, TPTR) ((uint32_t)(TPTR - (MP)->start)/(MP)->blkSz)
#define BIDX(PTR, POFF)         (*(uint32_t*)((PTR)+(POFF)))

static inline void *mpool_alloc(mpool_t *mp)
{
    void *alloc_ptr = NULL;

    if(mp->numInited < mp->numOfBlks)
    {
        uint32_t *rec = (uint32_t*)ADDR_FROM_INDEX(mp, mp->numInited);
        *rec = mp->numInited + 1;
        ++mp->numInited;
    }
    if(mp->numFreeBlks)
    {
        alloc_ptr = mp->next;
        if(--mp->numFreeBlks)
        {
            mp->next = ADDR_FROM_INDEX(mp, *(uint32_t*)mp->next);
        }
        else
        {
            mp->next = NULL;
        }
    }
    return alloc_ptr;
}

static inline void mpool_dealloc(mpool_t *mp, void *ptr)
{
    if(!mp || !ptr)
        return;
    if(mp->next)
    {
        *(uint32_t*)ptr = IDX_FROM_ADDR(mp, mp->next);
    }
    else
    {
        *(uint32_t*)ptr = mp->numOfBlks;
    }
    mp->next = (uint8_t*)ptr;
    mp->numFreeBlks++;
}

static inline void mpool_info(mpool_t *mp, char *label)
{
    printf("[%s] numOfBlks=%u, numInited=%u, numFreeBlks=%u, "
        "start=%p, next=%p\n",
        label, mp->numOfBlks, mp->numInited, mp->numFreeBlks,
        mp->start, mp->next);
}

