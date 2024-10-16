module resources.data.experimental.pdc3;

import resources.all;

final class PDC3 {
public:
    this(string filename) {
        import std.file : read;

        enum TEST = false;

        static if(TEST) {
            bytes = [1,2,3,5, 3,2,0,2, 3,2,0,2, 7, 1,2,3, 8];
            writefln("%s", bytes);
        } else {
            this.bytes = cast(ubyte[])read(filename);
        }

        this.order0Model = new FastOrder0DynamicModel(257, 1);
        this.lengthModel = new FastOrder0DynamicModel(MAX_LENGTH-2);
        this.hashIndexModel = new LinearModel(1); // 8144
        this.listIndexModel = new FastOrder0DynamicModel(1, 1); // 1030
        this.coder = new ArithmeticCoder(order0Model);
        this.bitWriter = new BitWriter((it) {numBitsWritten+=8; outStream ~= it; });
    }
    void encode() {
        writefln("encoding...");

        coder.beginEncoding();

        // read from byte 4 onwards
        while(pos < bytes.length) {
            ubyte b = read();

            writefln("[%s] %s", pos, b);

            Tuple!(bool,"matchFound",uint,"hashIndex",uint,"listIndex", uint,"length") match = findMatch(b);
            if(match.matchFound) {
                // Output:
                //  - Special token 256
                //  - Length of match
                //  - Hash index of match
                //  - Index in the hash list

                if(match.listIndex >= listIndexModel.getNumSymbols()) {
                    auto num = match.listIndex+1 - listIndexModel.getNumSymbols();

                    writefln("match.listIndex = %s, numSymbols = %s, num = %s", match.listIndex, listIndexModel.getNumSymbols(), num);
                    listIndexModel.addSymbols(num);
                }
                if(match.hashIndex >= hashIndexModel.getNumSymbols()) {
                    auto num = match.hashIndex+1 - hashIndexModel.getNumSymbols();
                    hashIndexModel.addSymbols(num);
                }
                
                coder.encode(bitWriter, 256, order0Model);
                coder.encode(bitWriter, match.length-3, lengthModel);
                coder.encode(bitWriter, match.hashIndex, hashIndexModel);
                coder.encode(bitWriter, match.listIndex, listIndexModel);

                // skip length bytes
                writefln("  Skipping %s bytes", match.length-1);

                foreach(i; 0..match.length-1) {
                    hash(b);
                    pos++;
                    b = read();
                }

            } else {
                // output the byte
                coder.encode(bitWriter, b, order0Model);
            }

            hash(b);
            pos++;
        }

        dumpHash();

        coder.endEncoding(bitWriter);

        writefln("hash length = %s", memory.length);
        writefln("done. Written %s bits", numBitsWritten);
        writefln("listIndexModel.numSymbols = %s", listIndexModel.getNumSymbols());
        writefln("hashIndexModel.numSymbols = %s", hashIndexModel.getNumSymbols());
    }
private:
    enum MAX_LENGTH = 64;

    struct Value {
        uint index;
        uint[] list;
    }

    ubyte[] bytes;
    Value[uint] memory;
    uint historyKey;
    uint pos;
    ArithmeticCoder coder;
    EntropyModel order0Model;
    EntropyModel lengthModel;
    LinearModel hashIndexModel;
    FastOrder0DynamicModel listIndexModel;

    ulong numBitsWritten;
    ubyte[] outStream;
    BitWriter bitWriter; 

    ubyte read(int offset = 0) {
        return pos+offset < bytes.length ? bytes[pos+offset] : 0;
    }
    void hash(ubyte value) {
        import common : getOrAdd;

        historyKey <<= 8;
        historyKey |= value;

        if(pos < 2) return;

        Value hashValue = Value(memory.length.as!uint, null);
        auto p = memory.getOrAdd(historyKey&0xffffff, hashValue);
        (*p).list ~= pos-2;

        //writefln("  Hashed: (%s %s %s) @ [%s]", (historyKey>>>16)&0xff, (historyKey>>>8)&0xff, historyKey&0xff, pos-2);
    }   
    void dumpHash() {
        writefln("####################### Hash:");
        foreach(e; memory.byKeyValue) {
            writefln("(%s,%s,%s) = %s", (e.key>>>16)&0xff, (e.key>>>8)&0xff, (e.key&0xff), e.value);
        }
    }
    /** Look through past bytes for a match of at least 2 bytes */
    Tuple!(bool,uint,uint,uint) findMatch(ubyte a) {

        if(pos+2 >= bytes.length) return tuple(false,0u,0u,0u);

        ubyte b = read(1);
        ubyte c = read(2);

        uint key = (a<<16) | (b<<8) | c;

        auto p = key in memory;
        if(p) {
            uint[] list = (*p).list;
            uint bestLength = 0;
            uint bestIndex = 0;

            // Select match with best length
            foreach(i, u; list) {
                uint length = getMatchLength(u, pos);
                if(length > bestLength) {
                    bestLength = length;
                    bestIndex = i.as!uint;
                }
            }

            //writefln("  !! Match (%s %s %s) at [%s,%s] (match %s len %s)", a,b,c, (*p).index, bestIndex, bestIndex, bestLength);

            return tuple(true, (*p).index, bestIndex, bestLength);
        } 
        return tuple(false,0u,0u,0u);
    }
    /**
     * Check strings starting at a and b. Return the length of the match
     */
    uint getMatchLength(uint a, uint b) {
        if(a > b) { uint c = a; a = b; b = c; }
        assert(a<b);

        uint bStart = b;
        uint len = 0;
        while(a < bStart && b < bytes.length) {
            if(bytes[a++] != bytes[b++]) break;
            len++;
            if(len==MAX_LENGTH) break;
        }
        return len;
    }
}
