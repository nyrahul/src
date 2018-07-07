#include <stdio.h>
#include <stdint.h>

#define SEQ_WIN                 16
#define LPOP_INIT               (-(SEQ_WIN))
#define LPOP_INCR(X)            X=(X)<0?(++X):(++X)&0x7f;
#define LPOP_IS_GREATER(A, B)   (((A)>(B)) || ((B-A)>=SEQ_WIN))

int main(void)
{
    int i;
    int8_t seq;

    seq = LPOP_INIT;
    for(i=0;i<200;i++)
    {
        LPOP_INCR(seq);
    }
    printf("%u %d\n", (uint8_t)-16, -16);
    return 0;
}
