module resources.image.jpeg.jpeg_bitstream;

import resources.all;

/**
 * Big endian bit stream for reading jpeg scan data
 */
final class BitStream {
public:
    this(ubyte[] data) {
        this.data = data;
    }
    ubyte getBit() {
        uint bytePos = bitPos >> 3;
        if(bytePos >= data.length) return 0;

        ubyte b = data[bytePos];
        ubyte s = 7-(bitPos & 7);
        bitPos++;
        return (b >> s) & 1;
    }
    uint getNBits(uint n) {
        uint val;
        foreach(i; 0..n) {
            val <<= 1;
            val += getBit();
        }
        return val;
    }
private:
    ubyte[] data;
    uint bitPos;
}
