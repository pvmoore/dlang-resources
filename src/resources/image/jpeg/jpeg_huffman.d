module resources.image.jpeg.jpeg_huffman;

import resources.all;
import resources.image.jpeg.jpeg_bitstream;

struct HuffKey {
    uint codeLength;
    uint code;
}

struct JPEGHuffmanTable {
public:
    this(ubyte[] counts, ubyte[] lengths) {
        buildTable(counts, lengths);
    }
    ubyte read(BitStream bits) {
        uint code = 0;
        uint codeLength = 1;
        while(codeLength <= 16) {
            code = (code << 1) | bits.getBit();
            auto ptr = HuffKey(codeLength, code) in table;
            if(ptr) {
                return *ptr;
            }
            codeLength++;
        }
        throwIf(true, "Symbol not found in Huffman table: %s", HuffKey(codeLength, code));
        assert(false);
    }
private:
    ubyte[HuffKey] table;

    void buildTable(ubyte[] counts, ubyte[] lengths) {
        uint code;
        uint lengthIndex;
        foreach(i, count; counts) {
            foreach(c; 0..count) {
                table[HuffKey(i.as!uint+1, code)] = lengths[lengthIndex++];
                code++;
            }
            code <<= 1;
        }
    }
}
