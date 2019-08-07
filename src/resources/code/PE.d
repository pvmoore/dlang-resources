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
    bool finishedReading;

    IMAGE_PE32_Plus image;
    COFF coff = null;
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
        readCOFFSections();

        finishedReading = true;
    }
    ubyte[] getCode() {
        if(!finishedReading) read();

        return coff.getCode();
    }
    uint getEntryPoint() {
        return image.entryPointAddr;
    }
private:
    /** Calculate the actual file position of the data for a particular data directory */
    long calcFilePosition(uint dataDirectoryIndex) {
        assert(dataDirectoryIndex < 16);
        auto vaddr = image.dataDirectories[dataDirectoryIndex].virtualAddr;
        foreach(i, ref section; coff.sections) {
            if(vaddr >= section.virtualAddr && section.virtualAddr + section.sizeofRawData > vaddr) {
                return (vaddr-section.virtualAddr) + section.ptrToRawData;
            }
        }
        return -1;
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

        coff = new COFF(filename, reader);
        coff.readHeader();

        chat("COFF header = %s", coff.header);
    }
    void readCOFFSections() {
        chat("Reading COFF sections ...");

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

        coff.readSections();
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

        chat("position = %s", reader.position);
    }

    void bail(string msg = null) {
        throw new Error(msg !is null ? msg : "This is not a valid PE file");
    }
}

//##################################################################################################

private:

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
