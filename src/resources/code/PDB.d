module resources.code.PDB;
/**
 *  https://en.wikipedia.org/wiki/Program_database
 *  https://github.com/microsoft/microsoft-pdb
 *
 *  https://llvm.org/docs/PDB/index.html
 *  https://llvm.org/docs/PDB/MsfFile.html
 *
 *  Assumes version 7
 */
import resources.all;

final class PDB {
private:
    string filename;
    ByteReader reader;
    MSFHeader msfHeader;
    PdbStreamHeader pdbHeader;      // stream 1
    TPIStreamHeader tpiHeader;      // stream 2
    NamedStreamMap namedStreamMap;
    Directory directory;
    uint[] directoryBlocks;
public:
    this(string filename) {
        this.filename = filename;
    }
    void read() {
        chat("Reading '%s'", filename);
        this.reader = new FileByteReader(filename);
        scope(exit) reader.close();

        readMSFHeader();
        readDirectory();
        readStream1();
        readStream2();
        readStream3();
    }
private:
    void bail(string msg = null) {
        throw new Error(msg !is null ? msg : "This is not a valid version 7.0 PDB file");
    }
    uint countBlocks(uint size) {
        import std.math : ceil;
        return cast(uint)ceil(cast(float)size / msfHeader.blockSize);
    }
    void moveToBlock(uint index) {
        reader.rewind();
        reader.skip(index*msfHeader.blockSize);
    }
    void readMSFHeader() {

        msfHeader.read(reader);

        if((cast(string)msfHeader.signature) != "Microsoft C/C++ MSF 7.00\r\n\x1ADS\0\0\0") {
            bail();
        }

        chat("%s", msfHeader);
    }
    void readDirectory() {
        chat("Reading directory ...");
        moveToBlock(msfHeader.blockMapIndex);

        auto numBlocks = countBlocks(msfHeader.numDirectoryBytes);
        chat("numBlocks = %s", numBlocks);
        for(auto i=0; i<numBlocks; i++) {
            auto b = reader.read!uint;
            directoryBlocks ~= b;
        }
        chat("directory blocks = %s", directoryBlocks);

        moveToBlock(directoryBlocks[0]);
        directory.numStreams = reader.read!uint;

        chat("num streams = %s", directory.numStreams);
        for(auto i=0; i<directory.numStreams; i++) {
            directory.streamSizes ~= reader.read!uint;
        }
        chat("sizes = %s", directory.streamSizes);

        foreach(size; directory.streamSizes) {
            auto count = countBlocks(size);

            uint[] blocks;
            for(auto i=0; i<count; i++) {
                blocks ~= reader.read!uint;
            }

            directory.streamBlocks ~= blocks;
        }
    }
    /** PDB Stream (stream 1) */
    void readStream1() {
        chat("stream 1 size = %s, blocks = %s", directory.streamSizes[1], directory.streamBlocks[1]);

        moveToBlock(directory.streamBlocks[1][0]);

        pdbHeader.read(reader);

        /* Named Stream Map */
        namedStreamMap.read(reader);
        chat("%s", namedStreamMap);

        /* Feature codes */
        auto pos  = directory.streamBlocks[1][0] * msfHeader.blockSize;
        auto size = directory.streamSizes[1];
        auto rem  = reader.position - pos;
        chat("rem = %s size = %s", rem, size);

        auto v = reader.read!uint;
        chat("v=%s", v);
    }
    /** TPI Stream (stream 2)*/
    void readStream2() {
        chat("stream 2 size = %s, blocks = %s", directory.streamSizes[2], directory.streamBlocks[2]);
        moveToBlock(directory.streamBlocks[2][0]);

        /* TPI Header */
        tpiHeader.read(reader);
        chat("%s", tpiHeader);

        /* Type Record Bytes
           https://llvm.org/docs/PDB/CodeViewTypes.html
        */
        auto numRecords = tpiHeader.typeIndexEnd - tpiHeader.typeIndexBegin;
        chat("num type numRecords = %s", numRecords);

        chat("num record bytes = %s", tpiHeader.typeRecordBytes);

        struct RecordHeader {
            enum Kind {
                LF_MODIFIER = 0x1001,
                LF_POINTER  = 0x1002
            }
            ushort len;
            ushort kind;

            string toString() const { return "0x%x %s".format(kind, len); }
        }

        // for(auto i=0; i<numRecords; i++) {
        //     // RecordHeader
        //     RecordHeader h;
        //     h.len  = reader.read!ushort;
        //     h.kind = reader.read!ushort;
        //     chat("RecordHeader=%s", h);

        //     if(i==3) break;

        //     switch(h.kind) with(RecordHeader.Kind) {
        //         case LF_MODIFIER:
        //             //ushort attr = reader.read!ushort;


        //             chat("LF_MODIFIER: %s", reader.readArray!ubyte(h.len));
        //             //chat("attr=%b", attr);
        //             break;
        //         case LF_POINTER:
        //             chat("LF_POINTER: %s", reader.readArray!ubyte(h.len));
        //             break;
        //         default:
        //             chat("LF_?: %s", reader.readArray!ubyte(h.len));
        //             break;
        //     }

        // }
    }
    /** DBI Stream (stream 3)*/
    void readStream3() {
        chat("stream 3 size = %s, blocks = %s", directory.streamSizes[3], directory.streamBlocks[3]);
        //moveToBlock(directory.streamBlocks[3][0]);

    }
}

private:

struct MSFHeader {
    ubyte[32] signature;
    uint blockSize;
    uint freeBlockMapBlock;
    uint numBlocks;
    uint numDirectoryBytes;
    uint reserved;
    uint blockMapIndex;

    void read(ByteReader r) {
        signature         = r.readArray!ubyte(32);
        blockSize         = r.read!uint;
        freeBlockMapBlock = r.read!uint;
        numBlocks         = r.read!uint;
        numDirectoryBytes = r.read!uint;
        reserved          = r.read!uint;
        blockMapIndex     = r.read!uint;
    }

    string toString() const {
        return "[SuperBlock blockSize: %s, freeBlockMap: %s, numBlocks: %s, dirBytes: %s, blockMap: %s]".format(
            blockSize, freeBlockMapBlock, numBlocks, numDirectoryBytes, blockMapIndex
        );
    }
}
struct Directory {
    uint numStreams;
    uint[] streamSizes;     // 1 per stream
    uint[][] streamBlocks;
}

struct PdbStreamHeader {
    enum PdbStreamVersion : uint {
        VC2 = 19941610,
        VC4 = 19950623,
        VC41 = 19950814,
        VC50 = 19960307,
        VC98 = 19970604,
        VC70Dep = 19990604,
        VC70 = 20000404,
        VC80 = 20030901,
        VC110 = 20091201,
        VC140 = 20140508,
    }

    PdbStreamVersion ver;
    uint signature;
    uint age;
    ubyte[16] guid;

    void read(ByteReader r) {
        ver         = cast(PdbStreamVersion)r.read!uint;
        signature   = r.read!uint;
        age         = r.read!uint;
        guid        = r.readArray!ubyte(16);
    }
}

struct NamedStreamMap {
    uint size;
    string[] keys;
    uint[] values;
    uint[] presentBitVector;
    uint[] deletedBitVector;

    void read(ByteReader reader) {
        auto len    = reader.read!uint;
        auto buffer = reader.readArray!ubyte(len);

        chat("len=%s %s", len, cast(string)buffer);

        this.size = reader.read!uint;
        auto numBuckets = reader.read!uint;

        auto words = reader.read!uint;
        for(auto i=0; i<words; i++) {
            this.presentBitVector ~= reader.read!uint;
        }
        words = reader.read!uint;
        chat("deleted bit words = %s", words);
        for(auto i=0; i<words; i++) {
            this.deletedBitVector ~= reader.read!uint;
        }
        chat("size = %s, numBuckets = %s, presentBitVector = %s, deletedBitVector = %s",
            this.size, numBuckets, this.presentBitVector, this.deletedBitVector);

        chat("%032b", this.presentBitVector[0]);

        for(auto i=0; i<numBuckets; i++) {
            auto key   = reader.read!uint;
            auto value = reader.read!uint;

            this.keys  ~= getKey(buffer, key);
            this.values ~= value;
        }
    }
    int getBlock(string name) {
        for(auto i=0; i<keys.length; i++) {

        }
        return -1;
    }

    string toString() const {

        string s = "[NamedStreamMap size: %s\n".format(size);
        for(auto i=0; i<keys.length; i++) {
            s ~= "    \"%s\" = %s\n".format(keys[i], values[i]);
        }

        return s ~ "]";
    }
private:
    string getKey(ref ubyte[] buffer, uint bufferIndex) const {
        import std.string : fromStringz;
        if(bufferIndex < buffer.length) {
            return cast(string)fromStringz(cast(char*)buffer.ptr+bufferIndex);
        }
        return null;
    }
}

struct TPIStreamHeader {
    TpiStreamVersion ver;
    uint headerSize;
    uint typeIndexBegin;
    uint typeIndexEnd;
    uint typeRecordBytes;

    ushort hashStreamIndex;
    ushort hashAuxStreamIndex;
    uint hashKeySize;
    uint numHashBuckets;
    int hashValueBufferOffset;
    uint hashValueBufferLength;
    int indexOffsetBufferOffset;
    uint indexOffsetBufferLength;
    int hashAdjBufferOffset;
    uint hashAdjBufferLength;

    void read(ByteReader r) {
        ver                     = cast(TpiStreamVersion)r.read!uint;
        headerSize              = r.read!uint;
        typeIndexBegin          = r.read!uint;
        typeIndexEnd            = r.read!uint;
        typeRecordBytes         = r.read!uint;
        hashStreamIndex         = r.read!ushort;
        hashAuxStreamIndex      = r.read!ushort;
        hashKeySize             = r.read!uint;
        numHashBuckets          = r.read!uint;
        hashValueBufferOffset   = r.read!int;
        hashValueBufferLength   = r.read!uint;
        indexOffsetBufferOffset = r.read!int;
        indexOffsetBufferLength = r.read!uint;
        hashAdjBufferOffset     = r.read!int;
        hashAdjBufferLength     = r.read!uint;
    }
}
enum TpiStreamVersion : uint {
  V40 = 19950410,
  V41 = 19951122,
  V50 = 19961031,
  V70 = 19990903,
  V80 = 20040203,
}