module resources.data.experimental.pdc3;

import resources.all;

final class PDC3 {
public:
    this(string filename) {
        import std.file : read;

        enum TEST = true;

        static if(TEST) {
            bytes = [1,2,3,5, 3,2,0,2, 3,2,0,2];
            writefln("%s", bytes);
        } else {
            this.bytes = cast(ubyte[])read(filename);
        }
    }
    void encode() {
        writefln("encoding...");

        assert(bytes.length > 3, "Fixme - handle very small inputs");

        // Read the first 3 bytes to get the history going
        ubyte b1 = read();
        ubyte b2 = read();
        ubyte b3 = read();

        historyKey |= b1;
        historyKey <<= 8;
        historyKey |= b2;

        hash(b3);

        // read from byte 4 onwards
        while(pos < bytes.length) {
            ubyte b = read();

            writefln("[%s] %s", pos-1, b);

            int matchPos = findMatch();
            if(matchPos!=-1) {
                // If this match has been used before then output Token B followed by the index
                // otherwise output Token A followed by the distance and then the length of the match
                
                
            } else {
                // output the byte
            }

            hash(b);
        }

        dumpHash();

        writefln("done");
    }
private:
    ubyte[] bytes;
    uint[][uint] memory;
    uint historyKey;
    uint pos;

    ubyte read() {
        return bytes[pos++];
    }
    void hash(ubyte value) {
        import common : getOrAdd;

        historyKey <<= 8;
        historyKey |= value;

        uint[] list;
        auto p = memory.getOrAdd(historyKey, list);
        *p ~= pos-3;
    }   
    void dumpHash() {
        foreach(e; memory.byKeyValue) {
            writefln("(%s,%s,%s) = %s", (e.key>>>16)&0xff, (e.key>>>8)&0xff, (e.key&0xff), e.value);
        }
    }
    /** Look through past bytes for a match of at least 2 bytes */
    int findMatch() {
        return -1;
    }
}
