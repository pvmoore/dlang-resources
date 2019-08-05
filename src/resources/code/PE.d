module resources.code.PE;
/**
 *  https://en.wikipedia.org/wiki/Portable_Executable
 *  https://docs.microsoft.com/en-us/windows/win32/debug/pe-format
 *  https://drive.google.com/file/d/0B3_wGJkuWLytbnIxY1J5WUs4MEk/view
 *
 */
import resources.all;

final class PE {
private:
    string filename;
    ByteReader reader;
    COFF coff;
    IMAGE_PE32_Plus image;
    SectionHeader[] sections;
    bool finishedReading;
public:
    this(string filename) {
        this.filename = filename;
    }
    void read() {
        chat("reading '%s'", filename);

        this.reader = new FileByteReader(filename);
        scope(exit) reader.close();
        chat("length: %s", reader.length);

        /* Skip to the end of the MS-DOS stub */
        reader.skip(60);
        auto offset = reader.read!uint;
        chat("offset = %s", offset);

        /* Skip to the signature */
        reader.skip(offset-reader.position);

        readSignature();
        readCOFFHeader();

        readImageHeader();

        finishedReading = true;
    }
    ubyte[] getCode() {
        if(!finishedReading) read();

        auto section = getSectionByName(".text");
        if(section) {
            auto start = section.ptrToRawData;
            auto size  = section.sizeofRawData;

            auto r = new FileByteReader(filename);
            scope(exit) r.close();
            r.skip(start);

            return r.readArray!ubyte(size);
        }
        return null;
    }
    uint getEntryPoint() {
        return image.entryPointAddr;
    }
private:
    /** Calculate the actual file position of the data for a particular data directory */
    long calcFilePosition(uint dataDirectoryIndex) {
        assert(dataDirectoryIndex < 16);
        auto vaddr = image.dataDirectories[dataDirectoryIndex].virtualAddr;
        foreach(i, ref section; sections) {
            if(vaddr >= section.virtualAddr && section.virtualAddr + section.sizeofRawData > vaddr) {
                return (vaddr-section.virtualAddr) + section.ptrToRawData;
            }
        }
        return -1;
    }
    SectionHeader* getSectionByName(string name) {
        foreach(ref s; sections) {
            if((cast(string)s.name[0..8]).startsWith(name)) {
                return &s;
            }
        }
        return null;
    }
    void readSignature() {
        /* ['P', 'E', 0, 0] */
        auto sig = reader.read!uint;
        if(sig != 0x00004550) {
            bail();
        }
    }
    void readCOFFHeader() {
        chat("Reading COFF header ...");

        coff.machine         = reader.read!ushort;
        coff.numSections     = reader.read!ushort;
        coff.timeStamp       = reader.read!uint;
        coff.symbolTablePtr  = reader.read!uint;
        coff.numSymbols      = reader.read!uint;
        coff.optHeaderSize   = reader.read!ushort;
        coff.characteristics = reader.read!ushort;
        chat("COFF = %s", coff);
    }
    void readImageHeader() {
        chat("Reading IMAGE header ...");

        image.magic                 = reader.read!ushort;
        image.majorLinkerVersion    = reader.read!ubyte;
        image.minorLinkerVersion    = reader.read!ubyte;
        image.codeSize              = reader.read!uint;
        image.initialisedDataSize   = reader.read!uint;
        image.uninitialisedDataSize = reader.read!uint;
        image.entryPointAddr        = reader.read!uint;
        image.codeBase              = reader.read!uint;

        image.imageBase = reader.read!ulong;
        image.sectionAlignment = reader.read!uint;
        image.fileAlignment = reader.read!uint;
        image.majorOSVersion = reader.read!ushort;
        image.minorOSVersion = reader.read!ushort;
        image.majorImageVersion = reader.read!ushort;
        image.minorImageVersion = reader.read!ushort;
        image.majorSubsystemVersion = reader.read!ushort;
        image.minorSubsystemVersion = reader.read!ushort;
        image.win32VersionValue = reader.read!uint;
        image.imageSize = reader.read!uint;
        image.headersSize = reader.read!uint;
        image.checksum = reader.read!uint;
        image.subsystem = reader.read!ushort;
        image.dllCharacteristics = reader.read!ushort;
        image.stackReserveSize = reader.read!ulong;
        image.stackCommitSize = reader.read!ulong;
        image.heapReserveSize = reader.read!ulong;
        image.heapCommitSize = reader.read!ulong;
        image.loaderFlags = reader.read!uint;
        image.numRvaAndSizes = reader.read!uint;
        chat("IMAGE = %s", image);

        if(!image.isPE32Plus()) {
            bail("Can only handle PE32+ images, not PE32");
        }

        chat("imageBase = 0x%x", image.imageBase);

        chat("num data directories = %s", image.numRvaAndSizes);

        /* Data directories
            0  - export
            1  - import
            2  - resource
            3  - exception
            4  - security
            5  - basereloc
            6  - debug
            7  - copyright
            8  - globalptr
            9  - tls
            10 - load config
            11 - bound import
            12 - iat
            13 - delay import
            14 - com descriptor
            15 - ?
        */
        for(auto i =0; i<image.numRvaAndSizes; i++) {
            image.dataDirectories[i].virtualAddr = reader.read!uint;
            image.dataDirectories[i].size        = reader.read!uint;
            if(image.dataDirectories[i].size > 0) {
                chat("dir[%s] %s bytes @ %s", i, image.dataDirectories[i].size, image.dataDirectories[i].virtualAddr);
            }
        }

        chat("import table = %s", image.dataDirectories[0].size);

        chat("section alignment = %s", image.sectionAlignment);

        /*
            .text   - code
            .data   - initialised data
            .rdata  - readonly initialised data
            .idata  - import tables
            .pdata  - exception info
            .rsrc   - resource info
            .bss    - uninitialised data
            .reloc  - image relocations
            .tls    - thread local storage

            .minfo  -
            .tp
            .dp
            _RDATA
        */

        /*
        idata
            4381184
            4394500
        */

        for(auto i=0; i<coff.numSections; i++) {
            SectionHeader section;
            section.name = reader.readArray!ubyte(8);
            section.virtualSize = reader.read!uint;
            section.virtualAddr = reader.read!uint;
            section.sizeofRawData = reader.read!uint;
            section.ptrToRawData = reader.read!uint;
            section.ptrToRelocations = reader.read!uint;
            section.ptrToLineNumbers = reader.read!uint;
            section.numRelocations = reader.read!ushort;
            section.numLineNumbers = reader.read!ushort;
            section.characteristics = reader.read!uint;
            sections ~= section;

            chat("%s", section.toString());
        }

        chat("position = %s", reader.position);
    }

    void bail(string msg = null) {
        throw new Error(msg !is null ? msg : "This is not a valid PE file");
    }
}

//##################################################################################################

private:

struct COFF {
    ushort machine;
    ushort numSections;
    uint timeStamp;
    uint symbolTablePtr;    // expected to be 0, coff debugging info is deprecated
    uint numSymbols;        // expected to be 0, coff debugging info is deprecated
    ushort optHeaderSize;
    ushort characteristics; // Characteristics

    bool isImage() { return 0!=(characteristics & Characteristics.IMAGE_FILE_EXECUTABLE_IMAGE); }

    string toString() const {
        return "[COFF machine: 0x%x, numSections: %s, timestamp: %s, symbolTablePtr: %s, numSymbols: %s, optHdrSize: %s, characteristics: 0x%x]".format(
            machine, numSections, timeStamp, symbolTablePtr,
            numSymbols, optHeaderSize, characteristics
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

struct IMAGE_PE32_Plus {
    ushort magic;
    ubyte majorLinkerVersion;
    ubyte minorLinkerVersion;
    uint codeSize;
    uint initialisedDataSize;
    uint uninitialisedDataSize;
    uint entryPointAddr;
    uint codeBase;

    ulong imageBase;
    uint sectionAlignment;
    uint fileAlignment;
    ushort majorOSVersion;
    ushort minorOSVersion;
    ushort majorImageVersion;
    ushort minorImageVersion;
    ushort majorSubsystemVersion;
    ushort minorSubsystemVersion;
    uint win32VersionValue;
    uint imageSize;
    uint headersSize;
    uint checksum;
    ushort subsystem;
    ushort dllCharacteristics;
    ulong stackReserveSize;
    ulong stackCommitSize;
    ulong heapReserveSize;
    ulong heapCommitSize;
    uint loaderFlags;       // reserved. must be 0
    uint numRvaAndSizes;
    DataDirectory[16] dataDirectories;

    bool isPE32Plus() { return magic == 0x20b; }

    ulong exportTableOffset() { return imageBase + dataDirectories[0].virtualAddr; }

    string toString() const {
        return "[IMAGE linker: %s.%s, codeSize: %s, initDataSize: %s, uninitDataSize: %s, entryPoint: %s, codeBase: %s]".format(
            majorLinkerVersion, minorLinkerVersion,
            codeSize, initialisedDataSize, uninitialisedDataSize,
            entryPointAddr, codeBase
        );
    }
}

struct DataDirectory {
    uint virtualAddr;
    uint size;
}

enum Subsystem {
    UNKNOWN                  = 0,
    NATIVE                   = 1,
    WINDOWS_GUI              = 2,
    WINDOWS_CUI              = 3,
    OS2_CUI                  = 5,
    POSIX_CUI                = 7,
    NATIVE_WINDOWS           = 8,
    WINDOWS_CE_GUI           = 9,
    EFI_APPLICATION          = 10,
    EFI_BOOT_SERVICE_DRIVER  = 11,
    EFI_RUNTIME_DRIVER       = 12,
    EFI_ROM                  = 13,
    XBOX                     = 14,
    WINDOWS_BOOT_APPLICATION = 16
}
enum DLLCharacteristics {
    HIGH_ENTROPY_VA         = 0x20,
    DYNAMIC_BASE            = 0x40,
    FORCE_INTEGRITY         = 0x80,
    NX_COMPAT               = 0x100,
    NO_ISOLATION            = 0x200,
    NO_SEH                  = 0x400,
    NO_BIND                 = 0x800,
    APPCONTAINER            = 0x1000,
    WDM_DRIVER              = 0x2000,
    GUARD_CF                = 0x4000,
    TERMINAL_SERVER_AWARE   = 0x8000
}

struct SectionHeader {
    ubyte[8] name;
    uint virtualSize;
    uint virtualAddr;
    uint sizeofRawData;
    uint ptrToRawData;
    uint ptrToRelocations;
    uint ptrToLineNumbers;
    ushort numRelocations;
    ushort numLineNumbers;
    uint characteristics;   // SectionFlags

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

enum SectionFlags {
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