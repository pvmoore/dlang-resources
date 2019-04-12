module resources.data.zip;

import resources.all;
/**
 *  https://en.wikipedia.org/wiki/Zip_(file_format)
 *  https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
 *
 *  Todo:
 *      - Support Zip64
 */
final class Zip {
private:
    string archiveFilename;
    InternalEntry[ulong] entryByOffset;      // key = offset from start of archive
    InternalEntry[string] entryByFilename; 
    EOCDRecord eocd;
    bool isModified; 
    ulong totalCompressedSize;
    ulong totalUncompressedSize;

    final static class InternalEntry {
        LocalFileHeader localHeader;
        CentralDirectoryFileHeader cdHeader;
        ulong offset;
        uint relativeDataOffset; // relative to offset
        ubyte[] uncompressedData;
    }
public:
    final class Entry {
        private InternalEntry internalEntry;
        string filename;
        ulong uncompressedSize;
        ulong compressedSize;

        this(InternalEntry e) {
            this.internalEntry    = e;
            this.filename         = cast(string)e.localHeader.filename;
            this.uncompressedSize = e.localHeader.uncompressedSize;
            this.compressedSize   = e.localHeader.compressedSize;
        }
        bool hasBeenDecompressed() { 
            return internalEntry.uncompressedData.length > 0 || internalEntry.localHeader.uncompressedSize==0;
        }
        ubyte[] getUncompressed() {
            if(hasBeenDecompressed()) {
                return internalEntry.uncompressedData.dup;
            }
            
            // assume this is a file archive
            expect(archiveFilename !is null);

            auto byteReader = new FileByteReader(archiveFilename);
            scope(exit) byteReader.close();
            byteReader.skip(internalEntry.offset + internalEntry.relativeDataOffset);

            if(isCompressed(internalEntry.localHeader.compressionMethod)) {
                if(isDeflate(internalEntry.localHeader.compressionMethod)) {
                    internalEntry.uncompressedData = new Inflate().decompress(byteReader);
                } 
            } else {
                internalEntry.uncompressedData = byteReader.readArray!ubyte(internalEntry.localHeader.uncompressedSize);
            }
            return internalEntry.uncompressedData;
        }
        override string toString() const {
            return "Zip.Entry(\"%s\")".format(filename);
        }
    }
    this(string filename = null) {
        this.archiveFilename = filename;

        if(filename !is null && From!"std.file".exists(filename)) {
            open();
        }
    }
    void flush() {
        if(isModified && archiveFilename !is null) {
            // write back to disk
        }
    }
    void close() {
        flush();
    }
    string getComment() {
        return cast(string)eocd.comment;
    }
    ulong getCompressedSize() {
        return totalCompressedSize;
    }
    ulong getUncompressedSize() {
        return totalUncompressedSize;
    }
    ulong getNumEntries() { 
        return entryByOffset.length; 
    }
    string[] getFilenames() {
        return entryByFilename.keys();
    }
    Entry get(string filename) {
        auto ptr = filename in entryByFilename;
        if(ptr) {
            return new Entry(*ptr);
        }
        return null;
    }
private:
    void open() {
        auto r = new FileByteReader(archiveFilename);
        scope(exit) r.close();

        while(!r.eof) {
            uint signature = r.read!uint;

            switch(signature) {
                case 0x04034b50 : 
                    readLocalFileHeader(r);
                    break;
                case 0x02014b50:
                    readCentralDirectoryFileHeader(r);
                    break;
                case 0x6054b50:
                    readEOCDRecord(r);
                    break;
                case 0x06064b50: // Zip64 end of central directory record
                case 0x07064b50: // Zip64 end of central directory locator

                    throw new Error("Zip64 not supported");
                default:
                    throw new Error("Unhandled signature: %x".format(signature));
            }
        } 
        if(eocd.numRecordsOnDisk != entryByOffset.length || entryByOffset.length!=entryByFilename.length) {
            throw new Error("Corrupt ZIP file");
        }
    }
    struct LocalFileHeader {
        uint signature = 0x04034b50;
        ushort versionNeeded;
        ushort generalBitFlag;
        ushort compressionMethod;
        ushort filelastModifiedTime;
        ushort filelastModifiedDate;
        uint crc32;
        uint compressedSize;
        uint uncompressedSize;
        ushort filenameLength;
        ushort extraFieldLength;
        ubyte[] filename;
        ubyte[] extraField;
    }
    void readLocalFileHeader(ByteReader r) {
        ulong offset = r.position-4;

        LocalFileHeader h;
        h.versionNeeded = r.read!ushort;
        h.generalBitFlag = r.read!ushort;
        h.compressionMethod = r.read!ushort;
        h.filelastModifiedTime = r.read!ushort;
        h.filelastModifiedDate = r.read!ushort;
        h.crc32 = r.read!uint;
        h.compressedSize = r.read!uint;
        h.uncompressedSize = r.read!uint;
        h.filenameLength = r.read!ushort;
        h.extraFieldLength = r.read!ushort;
        h.filename = r.readArray!ubyte(h.filenameLength);
        h.extraField = r.readArray!ubyte(h.extraFieldLength);

        //writefln("versionNeeded = %s", h.versionNeeded);
        //writefln("compressionMethod = %s", h.compressionMethod);
        // chat("filename = %s", cast(char[])h.filename);
        //writefln("extra = %s", h.extraFieldLength);
        //writefln("extra = %s", h.extraField);
        // chat("file pos = %s", r.position);

        ulong dataOffset = r.position;

        if(isCompressed(h.compressionMethod)) {
            r.skip(h.compressedSize);
        } else {
            r.skip(h.uncompressedSize);
        }

        if(h.generalBitFlag & 8) {
            throw new Error("Stream data not supported");
        }

        if(h.generalBitFlag & (1<<3)) {
            // DataDescriptor

            h.crc32 = r.read!uint;
            if(h.crc32==0x08074b50) {
                h.crc32 = r.read!uint;        
            }
            h.compressedSize = r.read!uint;
            h.uncompressedSize = r.read!uint;
        }
        
        //chat("compressedSize = %s", h.compressedSize);
        //chat("uncompressedSize = %s", h.uncompressedSize);
        
        auto entry = new InternalEntry;
        entry.localHeader         = h;
        entry.offset              = offset;
        entry.relativeDataOffset  = (dataOffset - offset).as!uint;

        entryByOffset[offset] = entry;

        totalCompressedSize   += h.compressedSize;
        totalUncompressedSize += h.uncompressedSize;
    }
    struct CentralDirectoryFileHeader {
        uint signature = 0x02014b50;
        ushort versionMadeBy;
        ushort versionNeeded;
        ushort generalBitFlag;
        ushort compressionMethod;
        ushort filelastModifiedTime;
        ushort filelastModifiedDate;
        uint crc32;
        uint compressedSize;
        uint uncompressedSize;
        ushort filenameLength;
        ushort extraFieldLength;
        ushort commentLength;
        ushort startDiskNumber;
        ushort internalFileAttributes;
        uint externalFileAttributes;
        uint relativeOffsetOfLFH;
        ubyte[] filename;
        ubyte[] extraField;
        ubyte[] comment;
    }
    void readCentralDirectoryFileHeader(ByteReader r) {
        CentralDirectoryFileHeader h;

        h.versionMadeBy = r.read!ushort;
        h.versionNeeded = r.read!ushort;
        h.generalBitFlag = r.read!ushort;
        h.compressionMethod = r.read!ushort;
        h.filelastModifiedTime = r.read!ushort;
        h.filelastModifiedDate = r.read!ushort;
        h.crc32 = r.read!uint;
        h.compressedSize = r.read!uint;
        h.uncompressedSize = r.read!uint;
        h.filenameLength = r.read!ushort;
        h.extraFieldLength = r.read!ushort;
        h.commentLength = r.read!ushort;
        h.startDiskNumber = r.read!ushort;
        h.internalFileAttributes = r.read!ushort;
        h.externalFileAttributes = r.read!uint;
        h.relativeOffsetOfLFH = r.read!uint;
        h.filename = r.readArray!ubyte(h.filenameLength);
        h.extraField = r.readArray!ubyte(h.extraFieldLength);
        h.comment = r.readArray!ubyte(h.commentLength);

        // chat("\tFilename: %s", cast(char[])h.filename);
        // chat("\tComment: %s", cast(char[])h.comment);
        // chat("\tCompressed size: %s", h.compressedSize);
        // chat("\tUncompressed size: %s", h.uncompressedSize);
        // chat("\tMethod: %s", h.compressionMethod);
        // chat("\tOffset: %s", h.relativeOffsetOfLFH);
        // chat("\tVer made by: %s.%s", (h.versionMadeBy&0xff)/10, (h.versionMadeBy&0xff)%10);
        // chat("\tVer needed: %s.%s", (h.versionNeeded&0xff)/10, (h.versionNeeded&0xff)%10);

       // writefln("%s external = %s", cast(string)h.filename, h.externalFileAttributes);

        if(h.generalBitFlag&(1<<0)) {
            throw new Error("Encrypted archive not supported");
        }
        if(h.generalBitFlag&(1<<5)) {
            throw new Error("Patched data not supported");
        }
        if(h.generalBitFlag&(1<<6)) {
            throw new Error("Strong encryption not supported");
        }
        if(h.generalBitFlag&(1<<11)) { 
            // Filename and comment fields are UTF8
        } 
        if(h.generalBitFlag&(1<<13)) { 
            throw new Error("Strong encryption not supported");
        }
        if(isDeflate(h.compressionMethod)) {
            // Bit 2  Bit 1
            // 0      0    Normal (-en) compression option was used.
            // 0      1    Maximum (-exx/-ex) compression option was used.
            // 1      0    Fast (-ef) compression option was used.
            // 1      1    Super Fast (-es) compression option was used.
            // final switch((h.generalBitFlag>>1)&0b11) {
            //     case 0: chat("\tNormal (-en)"); break;
            //     case 1: chat("\tMaximum (-exx/-ex)"); break;
            //     case 2: chat("\tFast (-ef)"); break;
            //     case 3: chat("\tSuper Fast (-es)"); break;
            // } 
        }
        if(isCompressed(h.compressionMethod) && !isDeflate(h.compressionMethod)) {
            throw new Error("Compression method %s not supported".format(h.compressionMethod));
        }

        auto entry = entryByOffset[h.relativeOffsetOfLFH];
        if(entry is null) throw new Error("Corrupt ZIP file");

        string filename = cast(string)h.filename;

        entryByFilename[filename] = entry;
    }
    struct EOCDRecord { // End of central directory record
        uint signature;
        ushort diskNumber;
        ushort directoryStartDisk;
        ushort numRecordsOnDisk;
        ushort totalNumRecords;
        uint directorySize;
        uint directoryOffset;
        ushort commentLength;
        ubyte[] comment;
    }
    void readEOCDRecord(ByteReader r) {
        EOCDRecord h;

        h.diskNumber = r.read!ushort;
        h.directoryStartDisk = r.read!ushort;
        h.numRecordsOnDisk = r.read!ushort;
        h.totalNumRecords = r.read!ushort;
        h.directorySize = r.read!uint;
        h.directoryOffset = r.read!uint;
        h.commentLength = r.read!ushort;
        h.comment = r.readArray!ubyte(h.commentLength);

        eocd = h;
    }

    static bool isCompressed(ushort s) { return s!=0; }
    static bool isDeflate(ushort s)    { return s==8; }
    static bool isDeflate64(ushort s)  { return s==9; }
    static bool isBZIP2(ushort s)      { return s==12; }
    static bool isLZMA(ushort s)       { return s==14; }
    static bool isPPMd(ushort s)       { return s==98; } // PPMd version I, Rev 1
}