module resources.algorithms.deflate.MetaHuffman;

import resources.all;

/**
 *  A Huffman tree which is used to generate the literal and distance trees.
 */
final class MetaHuffman : HuffmanCoder {
private:
    __gshared const uint[] BL_ORDER = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
    static HuffmanCoder fixedLiteralTree, fixedDistanceTree;
public:
    /**
     *  Create from count x 3bit lengths.
     */
    static MetaHuffman readBitLengths(BitReader r, uint count) {
        uint[19] bitLengths;

        for(auto i=0; i<count; i++) {
            auto len = r.read(3); 
            bitLengths[BL_ORDER[i]] = len; 
        }

        return new MetaHuffman().createFromBitLengths(bitLengths)
                                .as!MetaHuffman;
    }
    /**
     *  Fixed Huffman literal/lengths tree for blocks with BTYPE = 01
     */
    static HuffmanCoder getFixedLiteralTree() {
        if(fixedLiteralTree is null) {
            uint[288] bitLengths;
            bitLengths[  0..144] = 8;
            bitLengths[144..256] = 9;
            bitLengths[256..280] = 7;
            bitLengths[280..288] = 8;
            fixedLiteralTree = new HuffmanCoder().createFromBitLengths(bitLengths);
        }
        return fixedLiteralTree;
    }
    /**
     *  Fixed Huffman distances tree for blocks with BTYPE = 01
     */
    static HuffmanCoder getFixedDistanceTree() {
        if(fixedDistanceTree is null) {
            uint[32] bitLengths;
            bitLengths[] = 5;
            fixedDistanceTree = new HuffmanCoder().createFromBitLengths(bitLengths);
        }
        return fixedDistanceTree;
    }
    HuffmanCoder decodeTree(BitReader r, int count) {
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
        return new HuffmanCoder().createFromBitLengths(lengths);
    }
}
