import math

def isSquare(val):
    if(val <= 0):
        return false
    sr = int(math.sqrt(val))
    return ((sr*sr)==val)

res = [] 
def solution(area):
    # Your code here
    for val in range(area, 0, -1):
        x = isSquare(val)
        if(x):
            res.append(val)
            solution(area-val)
            return res
    return res
