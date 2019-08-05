module resources.code.COFF;

import resources.all;

final class COFF {
private:
    string filename;
    ByteReader reader;
    COFFHeader coff;
    SectionHeader[] sections;
    bool finishedReading;
public:
    this(string filename) {
        this.filename = filename;
    }
    void read() {
        this.reader = new FileByteReader(filename);
        scope(exit) reader.close();

        chat("Reading object %s", filename);

        coff = reader.read!COFFHeader;

        chat("%s", coff);

        if(coff.machine != 0x8664) {
            bail("Only x8664 object files are supported");
        }

        for(auto i=0; i<coff.numSections; i++) {
            sections ~= reader.read!SectionHeader;
        }

        foreach(ref s; sections) {
            chat("%s", s.toString());
        }

        finishedReading = true;
    }
    ubyte[] getCode() {
        if(!finishedReading) read();

        ubyte[] code;
        auto r = new FileByteReader(filename);
        scope(exit) r.close();

        struct S { string name; uint start; uint size; }

        S[] codeSections;

        /* Gather all .text$? sections */
        foreach(ref s; sections) {
            if(s.name[0..5] == ".text") {
                auto start = s.ptrToRawData;
                auto size  = s.sizeofRawData;

                codeSections ~= S(cast(string)s.name, start, size);
            }
        }

        /* Sort them in lexographic order */
        import std.algorithm.mutation : SwapStrategy;
        import std.algorithm.sorting : sort;
        import std.algorithm.comparison : cmp;

        alias sorter = (S a, S b) => cmp(a.name, b.name) < 0;

        codeSections.sort!(sorter, SwapStrategy.stable);

        foreach(ref s; codeSections) {

            //chat("==> %s %s %s", s.name, s.start, s.size);

            r.rewind();
            r.skip(s.start);

            code ~= r.readArray!ubyte(s.size);
        }

        return code;
    }
private:
    void bail(string msg = null) {
        throw new Error(msg !is null ? msg : "Something went wrong");
    }
}

private:

struct COFFHeader { align(1):
    ushort machine;
    ushort numSections;
    uint timeStamp;
    uint symbolTablePtr;    // expected to be 0, coff debugging info is deprecated
    uint numSymbols;        // expected to be 0, coff debugging info is deprecated
    ushort optHeaderSize;
    ushort characteristics; // Characteristics

    string toString() const {
        return "[COFF machine: 0x%x, numSections: %s, timestamp: %s, symbolTablePtr: %s, numSymbols: %s, characteristics: 0x%x]".format(
            machine, numSections, timeStamp, symbolTablePtr,
            numSymbols, characteristics
        );
    }
}

enum Characteristics {
    IMAGE_FILE_RELOCS_STRIPPED          = 1,
    IMAGE_FILE_EXECUTABLE_IMAGE         = 2,
    IMAGE_FILE_LINE_NUMS_STRIPPED       = 4,
    IMAGE_FILE_LOCAL_SYMS_STRIPPED      = 8,
    IMAGE_FILE_AGGRESSIVE_WS_TRIM       = 0x10,
    IMAGE_FILE_LARGE_ADDRESS_AWARE      = 0x20,
    // reserved 0x40
    IMAGE_FILE_BYTES_REVERSED_LO        = 0x80,
    IMAGE_FILE_32BIT_MACHINE            = 0x100,
    IMAGE_FILE_DEBUG_STRIPPED           = 0x200,
    IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP  = 0x400,
    IMAGE_FILE_NET_RUN_FROM_SWAP        = 0x800,
    IMAGE_FILE_SYSTEM                   = 0x1000,
    IMAGE_FILE_DLL                      = 0x2000,
    IMAGE_FILE_UP_SYSTEM_ONLY           = 0x4000,
    IMAGE_FILE_BYTES_REVERSED_HI        = 0x8000
}

struct SectionHeader { align(1):
    ubyte[8] name;
    uint virtualSize;
    uint virtualAddr;
    uint sizeofRawData;
    uint ptrToRawData;
    uint ptrToRelocations;
    uint ptrToLineNumbers;
    ushort numRelocations;
    ushort numLineNumbers;
    SectionFlags characteristics;

    string toString() const {
        return "[Section '%s' (%s bytes @ %s), raw: (%s bytes @ %s)] reloc: (%s @ %s) lineNums: (%s @ %s) flags:0x%x".format(
            cast(string)name[0..8],
            virtualSize,
            virtualAddr,
            sizeofRawData,
            ptrToRawData,
            ptrToRelocations,
            numRelocations,
            ptrToLineNumbers,
            numLineNumbers,
            characteristics
        );
    }
}

enum SectionFlags : uint {
    TYPE_NO_PAD             = 8,
    CNT_CODE                = 0x20,
    CNT_INITIALIZED_DATA    = 0x40,
    CNT_UNINITIALIZED_DATA  = 0x80,
    LNK_OTHER               = 0x100,
    LNK_INFO                = 0x200,
    LNK_REMOVE              = 0x800,
    LNK_COMDAT              = 0x1000,
    GPREL                   = 0x8000,
    ALIGN_1BYTES            = 0x100000,
    ALIGN_2BYTES            = 0x200000,
    ALIGN_4BYTES            = 0x300000,
    ALIGN_8BYTES            = 0x400000,
    ALIGN_16BYTES           = 0x500000,
    ALIGN_32BYTES           = 0x600000,
    ALIGN_64BYTES           = 0x700000,
    ALIGN_128BYTES          = 0x800000,
    ALIGN_256BYTES          = 0x900000,
    ALIGN_512BYTES          = 0xa00000,
    ALIGN_1024BYTES         = 0xb00000,
    ALIGN_2048BYTES         = 0xc00000,
    ALIGN_4096BYTES         = 0xd00000,
    ALIGN_8192BYTES         = 0xe00000,
    LNK_NRELOC_OVFL         = 0x1000000,
    MEM_DISCARDABLE         = 0x2000000,
    MEM_NOT_CACHED          = 0x4000000,
    MEM_NOT_PAGED           = 0x8000000,
    MEM_SHARED              = 0x10000000,
    MEM_EXECUTE             = 0x20000000,
    MEM_READ                = 0x40000000,
    MEM_WRITE               = 0x80000000
}