/*
Read/Write bits to buffer 0.1.2
by Luigi Auriemma
e-mail: aluigi@autistici.org
web:    aluigi.org

max 32 bits numbers supported (from 0 to 4294967295).
Probably not the fastest bit packing functions existent, but I like them.
*/



unsigned int read_bits(    // number read
  unsigned int bits,       // how much bits to read
  unsigned char *in,       // buffer from which to read the number
  unsigned int in_bits     // position of the buffer in bits
) {
    unsigned int    seek_bits,
                    rem,
                    seek = 0,
                    ret  = 0,
                    mask = 0xffffffff;

    if(bits > 32) return(0);
    if(bits < 32) mask = (1 << bits) - 1;
    for(;;) {
        seek_bits = in_bits & 7;
        ret |= ((in[in_bits >> 3] >> seek_bits) & mask) << seek;
        rem = 8 - seek_bits;
        if(rem >= bits) break;
        bits    -= rem;
        in_bits += rem;
        seek    += rem;
        mask     = (1 << bits) - 1;
    }
    return(ret);
}



unsigned int write_bits(   // position where the stored number finishs
  unsigned int data,       // number to store
  unsigned int bits,       // how much bits to occupy
  unsigned char *out,      // buffer on which to store the number
  unsigned int out_bits    // position of the buffer in bits
) {
    unsigned int    seek_bits,
                    rem,
                    mask;

    if(bits > 32) return(out_bits);
    if(bits < 32) data &= (1 << bits) - 1;
    for(;;) {
        seek_bits = out_bits & 7;
        mask = (1 << seek_bits) - 1;
        if((bits + seek_bits) < 8) mask |= ~(((1 << bits) << seek_bits) - 1);
        out[out_bits >> 3] &= mask; // zero
        out[out_bits >> 3] |= (data << seek_bits);
        rem = 8 - seek_bits;
        if(rem >= bits) break;
        out_bits += rem;
        bits     -= rem;
        data    >>= rem;
    }
    return(out_bits + bits);
}

