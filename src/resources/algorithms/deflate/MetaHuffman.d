module resources.algorithms.deflate.MetaHuffman;

import resources.algorithms.deflate;
import resources.all;

/**
 *  A Huffman tree which is used to generate the literal and distance trees.
 */
final class MetaHuffman : Huffman {
private:
    __gshared const uint[] BL_ORDER = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
public:
    this(uint[] bitLengths) {
        super(bitLengths);
    }
    /**
     *  Create from count x 3bit lengths.
     */
    static MetaHuffman readBitLengths(BitReader r, uint count) {
        uint[19] bitLengths;

        for(auto i=0; i<count; i++) {
            auto len = r.read(3); 
            bitLengths[BL_ORDER[i]] = len; 
        }

        return new MetaHuffman(bitLengths);
    }
    Huffman decodeTree(BitReader r, int count) {
        uint[] lengths;
        uint prevLen = 0;

        while(count>0) {
            auto code = decode(r);
            //chat("\tcode = %s", code);

            switch(code) {
                case 0:..case 15: 
                    lengths ~= code; prevLen = code; 
                    count--;
                    break;
                case 16: 
                    int n = r.read(2) + 3;
                    count -= n;
                    while(n>0) { lengths ~= prevLen; n--; }
                    break;
                case 17:
                    int n = r.read(3) + 3;
                    count -= n;
                    while(n>0) { lengths ~= 0; n--; }
                    break;
                case 18:
                    int n = r.read(7) + 11;
                    count -= n;
                    while(n>0) { lengths ~= 0; n--; }
                    break;
                default: 
                    throw new Error("Error in compressed data");
            }
        }
        if(count!=0) throw new Error("Error in compressed data");
        return new Huffman(lengths);
    }
}
