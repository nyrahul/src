#ifndef _MPOOL_H_
#define _MPOOL_H_

#define INFO(...)   \
    printf(__VA_ARGS__);\
    fflush(stdout);

typedef struct _fast_mpool_
{
    uint32_t    numOfBlks;
    uint32_t    blkSz;
    uint32_t    numInited;
    uint32_t    numFreeBlks;
    uint8_t     *start;
    uint8_t     *next;
}mpool_t;

#define MPOOL_NAME(NAME)    NAME##mpool
#define MPOOL_DEF(NAME)     mpool_t MPOOL_NAME(NAME);

#define MPOOL_STATS(LABEL, NAME)   \
{\
    mpool_t *mp = &MPOOL_NAME(NAME);\
    INFO("[%s] numOfBlks=%d, numInited=%d, numFreeBlks=%d, start=%p, next=%p\n",\
        LABEL, mp->numOfBlks, mp->numInited, mp->numFreeBlks, \
        mp->start, mp->next);\
}

#define MPOOL_INIT(NAME, BASEPTR, NUM_BLKS, STRUCT)    \
{\
    mpool_t *mp = &MPOOL_NAME(NAME);\
    mp->numInited   = 0;\
    mp->numFreeBlks = (NUM_BLKS);\
    mp->blkSz       = (sizeof(STRUCT));\
    mp->numOfBlks   = (NUM_BLKS);\
    mp->start       = (BASEPTR);\
    mp->next        = mp->start;\
}

#define MPOOL_DEINIT(NAME)      //For Future if needed

#define ADDR_FROM_INDEX(MP, I)  \
    ((MP)->start + ((I) * (MP)->blkSz))

#define MPOOL_ALLOC(NAME, OUTPTR)   \
{\
    mpool_t *mp = &MPOOL_NAME(NAME);\
    OUTPTR = NULL;\
    if(mp->numInited < mp->numOfBlks) \
    {\
        typeof(OUTPTR) rec = (typeof(OUTPTR))ADDR_FROM_INDEX(mp, mp->numInited);\
        rec->mpool_p = ++mp->numInited;\
    }\
    if(mp->numFreeBlks) \
    {\
        (OUTPTR) = (typeof(OUTPTR))mp->next;\
        if(--mp->numFreeBlks)\
        {\
            typeof(OUTPTR) tmp_rec = (typeof(OUTPTR))mp->next;\
            mp->next = ADDR_FROM_INDEX(mp, tmp_rec->mpool_p);\
        }\
        else\
        {\
            mp->next = NULL;\
        }\
    }\
}

#define IDX_FROM_ADDR(TPTR)  ((uint32_t)(TPTR - mp->start)/mp->blkSz)
#define MPOOL_DEALLOC(NAME, PTR)  \
{\
    typeof(PTR) rec = PTR;\
    if(rec)\
    {\
        mpool_t *mp = &MPOOL_NAME(NAME);\
        if(mp->next)\
        {\
            rec->mpool_p = IDX_FROM_ADDR(mp->next);\
        }\
        else\
        {\
            rec->mpool_p = mp->numOfBlks;\
        }\
        mp->next = (uint8_t*)PTR;\
        mp->numFreeBlks++;\
    }\
}

#endif //_MPOOL_H_
