module resources.data.lz4;
/**
 *  http://lz4.github.io/lz4/
 *  http://lz4.github.io/lz4/lz4_Frame_format.html
 *  http://lz4.github.io/lz4/lz4_Block_format.html
 *  http://fastcompression.blogspot.co.uk/2011/05/lz4-explained.html
 */
import resources.all;

final class LZ4 {
    static ubyte[] decompress(string filename) {
        auto lz4 = new LZ4Decompresor(filename);
        lz4.decompress();
        lz4.destroy();
        return lz4.data[];
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

final class LZ4Decompresor {
    ByteReader reader;
    ubyte[] data;
    string filename;
    File file;
    FLG flg;
    ulong uncompressedSize;
    ulong maxBlockSize;

    this(string filename) {
        this.filename = filename;
        this.reader   = new FileByteReader(filename);
    }
    void destroy() {
        file.close();
    }
    void decompress() {
        chat("Decompressing LZ4 '%s' (%s bytes)", filename, reader.length);

        while(!reader.eof()) {
            decodeFrame();
        }
    }
private:
    void decodeFrame() {
        uint magic = reader.read!uint;
        if(magic >= 0x184D2A50 && magic <= 0x184D2A5F) {
            // skippable frame
            uint size = reader.read!uint;
            chat("Skippable frame %x size %s", magic, size);
            auto userData = reader.readArray!ubyte(size);
            chat("UserData = %s", userData);
            return;
        }
        if(magic==0x184C2102) {
            chat("Legacy frame format");
        }
        expect(magic==0x184D2204);

        auto flg = FLG(reader.read!ubyte);
        expect(flg.version_==1);
        chat("FLG = %s", flg);

        auto bd = BD(reader.read!ubyte);
        maxBlockSize = bd.kb*1024;
        chat("BD = %s", bd);

        if(flg.contentSize) {
            uncompressedSize = reader.read!ulong;
        }

        ubyte HC = reader.read!ubyte;
        chat("HC=%s", HC);

        chat("uncompressedSize = %s", uncompressedSize);
        chat("maxBlockSize     = %s", maxBlockSize);

        while(decodeBlock()) {

        }

        if(flg.contentChecksum) {
            uint checksum = reader.read!uint;
            chat("content checksum=%x", checksum);
        }
    }
    uint decodeBlock() {
        chat("Block");

        uint size = reader.read!uint;
        bool isCompressed = ((size>>31)&1)==0;
        size &= (uint.max>>>1);
        chat("size=%s", size);

        if(size>0) {
            if(isCompressed) {
                decodeData(size);
            } else {
                data ~= reader.readArray!ubyte(size);
            }
        }

        if(flg.blockChecksum) {
            uint checksum = reader.read!uint;
        }
        return size;
    }
    void decodeData(uint size) {
        chat("Data");

        auto start = reader.position;
        auto end   = start+size;

        while(reader.position < end) {
            decodeSequence(end-reader.position);
        }
        chat("data end position=%s", reader.position);
    }
    void decodeSequence(ulong remainingBytes) {
        chat("Sequence (%s bytes remaining)", remainingBytes);
        ubyte token = reader.read!ubyte;
        ubyte hi    = token>>4;
        ubyte lo    = token&0b1111;
        chat("token hi=%s", hi);
        chat("token lo=%s", lo);

        // literals
        uint literals = getLength(hi);
        chat("literals=%s", literals); 
        if(literals>0) {
            auto d = reader.readArray!ubyte(literals);
            data ~= d;
        }

        // the last sequence ends after the literals
        if(1+literals==remainingBytes) return;

        // match copy
        long offset  = reader.read!ushort;
        long length  = getLength(lo)+4;
        chat("Match offset=%s length=%s", offset, length);

        void copy() {
            long pos  = data.length;
            long from = pos-offset;
            long to   = min(from+length, pos);
            data ~= data[from..to];

            length -= (to-from);
        }

        while(length>0) {
            copy();
            chat("now offset=%s length=%s", offset, length);
        }
    }
    uint getLength(ubyte nibble) {
        if(nibble<15) return nibble;
        uint len = nibble;
        while(true) {
            uint b = reader.read!ubyte;
            len += b;
            if(b<255) return len;
        }
        assert(false);
    }
}

struct FLG {
    ubyte version_;
    bool blockIndependence;
    bool blockChecksum;
    bool contentSize;
    bool contentChecksum;

    this(ubyte b) {
        version_          = (b>>6)&3;
        blockIndependence = (b>>5)&1;
        blockChecksum     = (b>>4)&1;
        contentSize       = (b>>3)&1;
        contentChecksum   = (b>>2)&1;
    }
    string toString() {
        return "FLG["~
            "ver=%s".format(version_) ~
            " blkInd=%s".format(blockIndependence)~
            " blkChecksum=%s".format(blockChecksum)~
            " contentSize=%s".format(contentSize)~
            " contentChecksum=%s".format(contentChecksum)~
            "]";
    }
}
struct BD {
    ubyte blockMaxSize;
    uint kb;
    
    this(ubyte b) {
        blockMaxSize = (b>>4)&0b111;
        kb           = [0,0,0,0,64,256,1024,4096][blockMaxSize];
    }
}

