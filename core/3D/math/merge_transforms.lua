return function(a,b)
    return {
        a[1] *b[1]+a[2] *b[5]+a[3] *b[9] +a[4] *b[13],
        a[1] *b[2]+a[2] *b[6]+a[3] *b[10]+a[4] *b[14],
        a[1] *b[3]+a[2] *b[7]+a[3] *b[11]+a[4] *b[15],
        a[1] *b[4]+a[2] *b[8]+a[3] *b[12]+a[4] *b[16],
        a[5] *b[1]+a[6] *b[5]+a[7] *b[9] +a[8] *b[13],
        a[5] *b[2]+a[6] *b[6]+a[7] *b[10]+a[8] *b[14],
        a[5] *b[3]+a[6] *b[7]+a[7] *b[11]+a[8] *b[15],
        a[5] *b[4]+a[6] *b[8]+a[7] *b[12]+a[8] *b[16],
        a[9] *b[1]+a[10]*b[5]+a[11]*b[9] +a[12]*b[13],
        a[9] *b[2]+a[10]*b[6]+a[11]*b[10]+a[12]*b[14],
        a[9] *b[3]+a[10]*b[7]+a[11]*b[11]+a[12]*b[15],
        a[9] *b[4]+a[10]*b[8]+a[11]*b[12]+a[12]*b[16],
        a[13]*b[1]+a[14]*b[5]+a[15]*b[9] +a[16]*b[13],
        a[13]*b[2]+a[14]*b[6]+a[15]*b[10]+a[16]*b[14],
        a[13]*b[3]+a[14]*b[7]+a[15]*b[11]+a[16]*b[15],
        a[13]*b[4]+a[14]*b[8]+a[15]*b[12]+a[16]*b[16]
    }
end