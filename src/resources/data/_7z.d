module resources.data._7z;

import resources.all;

/**
 * https://www.7-zip.org/
 * https://www.7-zip.org/recover.html
 * https://github.com/lvseouren/7zip/tree/master/CPP/7zip/Archive/7z
 * https://github.com/lvseouren/7zip/blob/master/DOC/7zFormat.txt
 *
 *
 */

final class _7ZipDecompressor {
private:
    string filename;
    FileByteReader reader;

    enum MethodID : ulong {
        Copy = 0, LZMA2 = 0x21, LZMA = 0x30101
    }

    static struct StartHeader {
        ushort formatVersion;
        ulong endHeaderOffset;
        ulong endHeaderLength;
        string toString() {
            return "StartHeader(version=0x%x, endHeaderOffset=%s, endHeaderLength=%s)".format(
                formatVersion, endHeaderOffset, endHeaderLength);
        }
    }
    static struct PackInfo {
        ulong packPos;
        ulong numPackStreams;
        ulong[] packSizes;
        string toString() {
            return "PackInfo(pos=%s, numStreams=%s, sizes=%s)".format(packPos, numPackStreams, packSizes);
        }
    }
    static struct BindPair {
        uint inIndex;
        uint outIndex;
        string toString() { return "BindPair(%s, %s)".format(inIndex, outIndex); }
    }
    static struct Coder {
        ulong numInStreams;
        ulong numOutStreams;
        ulong methodId;
        ubyte[] props;
        string toString() { return "Coder(numInStreams=%s, numOutStreams=%s, methodId=%x, props=%s)".format(
            numInStreams, numOutStreams, methodId, props); }
    }
    static struct Folder {
        Coder[] coders;
        BindPair[] bindPairs;
        uint[] packStreams;
        ulong[] unpackedSizes;
        string toString() {
            return "Folder(coders=%s, bindPairs=%s, packStreams=%s, unpackedSizes=%s)".format(
                coders, bindPairs, packStreams, unpackedSizes);
        }
    }
    static struct File {
        wchar[] name;
        ulong mtime;
        ulong size;
        uint crc;
        uint attrib;
        bool hasStream;
        bool isDir;
        bool isAnti;
        bool crcDefined;
        bool mTimeDefined;
        bool attribDefined;
        string toString() {
            return "File(%s,%s)".format(name, size);
        }
    }
    StartHeader header;
    PackInfo* packInfo;
    Folder[] folders;
    File[] files;
public:
    this(string filename) {
        this.filename = filename;
        this.reader   = new FileByteReader(filename);
    }
    void destroy() {
        this.reader.close();
    }
    void decompress() {
        chat("decompressing %s", filename);

        readStartHeader();
        readEndHeader();

        chat("folders: %s", folders);
        chat("files: %s", files);
        if(packInfo !is null) chat("packInfo: %s", packInfo.toString());


        expect(packInfo.packSizes.length==1);
        expect(folders.length==1);
        expect(folders[0].coders.length==1);

        Coder coder = folders[0].coders[0];

        auto compressedSize  = packInfo.packSizes[0];
        auto streamStart     = 32 + packInfo.packPos;
        auto compressedBytes = new ubyte[compressedSize];

        chat("Packed data offset = %s (%s bytes)", streamStart, compressedSize);

        {
            import std.stdio : File;
            auto file = File(filename, "rb");
            file.seek(streamStart);
            file.rawRead(compressedBytes);
            file.close();
        }

        // auto lzma = new LZMA(compressedBytes, coder.props);
        // auto uncompressedBytes = lzma.decompress();

    }
private:
    void bail() {
        throw new Error("'%s' is not a valid 7z file".format(filename));
    }
    void unsupported(string msg) {
        throw new Error("%s is unsupported".format(msg));
    }
    /// 0x7a371c27afbc
    void readMagic() {
        auto magic1 = reader.read!ushort;
        auto magic2 = reader.read!uint;

        if(magic1 != 0x7a37 || magic2 != 0x1c27afbc) {
            bail();
        }
    }
    /// Header is 32 bytes
    void readStartHeader() {
        readMagic();

        header.formatVersion = reader.read!ushort;

        uint crc = reader.read!uint;

        header.endHeaderOffset = reader.read!ulong;
        header.endHeaderLength = reader.read!ulong;

        uint endHeaderCrc = reader.read!uint;

        chat("%s", header);
    }
    ///
    void readEndHeader() {
        expect(reader.position==32);
        reader.skip(header.endHeaderOffset);

        decodeProperty();
    }
    /**
     * 0x01
     * [ ArchiveProperties ]
     * [ 0x03 AdditionalStreamsInfo ]
     * [ 0x04 MainStreamsInfo ]
     * [ FilesInfo ]
     * 0x00
     */
    void decode_01_Header() {
        chat("0x01 - Header...");

        while(decodeProperty()) {}
    }
    void decode_02_ArchiveProperties() {
        chat("0x02 - ArchiveProperties");
        todo();
    }
    /**
     * 0x04
     * [ PackInfo ]
     * [ CodersInfo ]
     * [ SubStreamsInfo ]
     * 0x00
     */
    void decode_04_MainStreamsInfo() {
        chat("0x04 - MainStreamsInfo...");

        while(decodeProperty()) {}
    }
    void decode_05_FilesInfo() {
        chat("0x05 - FilesInfo");

        auto numFiles = decodeUint64();
        chat("numFiles = %s", numFiles);

        files.length = numFiles;

        while(true) {
            auto propType = decodeUint64();
            chat("propType=0x%x", propType);
            if(propType==0) break;

            auto size = decodeUint64();
            chat("size = %s", size);

            switch(propType) {
                case 0x0E: // EmptyStream
                    todo();
                    break;
                case 0x0F: // EmptyFile
                    todo();
                    break;
                case 0x10: // Anti
                    todo();
                    break;
                case 0x11: // Names
                    chat("Names");
                    if(reader.read!ubyte!=0) unsupported("FilesInfo.Names external != 0");

                    auto namesLength = (size-1)/2;
                    if(namesLength&1) bail();

                    wchar[] names = reader.readArray!wchar(namesLength);
                    chat("names = %s", names);

                    auto tokens = names.split(0);
                    chat("tokens = %s", tokens);

                    foreach(i, ref file; files) {
                        file.name = tokens[i];
                    }

                    break;
                case 0x12: // CTime
                    todo();
                    break;
                case 0x13: // ATime
                    todo();
                    break;
                case 0x14: // Mtime
                    chat("MTime");

                    bool[] vec = decodeBoolVector(numFiles);
                    chat("vec = %s", vec);

                    if(reader.read!ubyte!=0) unsupported("FilesInfo.MTime.external != 0");

                    foreach(i, ref file; files) {
                        if(vec[i]) {
                            file.mTimeDefined = true;
                            file.mtime = reader.read!ulong;
                            chat("mtime = %s", files[i].mtime);
                        }
                    }
                    break;
                case 0x15: // Attributes
                    chat("Attributes");

                    bool[] vec = decodeBoolVector(numFiles);
                    chat("vec = %s", vec);

                    if(reader.read!ubyte!=0) unsupported("FilesInfo.Attributes.external != 0");

                    foreach(i, ref file; files) {
                        if(vec[i]) {
                            file.attribDefined = true;
                            file.attrib = reader.read!uint;
                            chat("attrib = %s", file.attrib);
                        }
                    }
                    break;
                case 0x19: // Dummy
                    reader.skip(size);
                    break;
                default:
                    unsupported("propType = %x".format(propType));
                    assert(false);
            }
        }
    }
    /**
     * 0x06
     * packPos
     * numPackStreams
     * [ size, packSizes ]
     * [ crc, packStreamDigests ]
     * 0x00
     */
    void decode_06_PackInfo() {
        chat("0x06 - PackInfo...");

        packInfo = new PackInfo;
        packInfo.packPos        = decodeUint64();
        packInfo.numPackStreams = decodeUint64();

        ubyte next = reader.read!ubyte;
        if(next==0x09) {
            foreach(i; 0..packInfo.numPackStreams) {
                packInfo.packSizes ~= decodeUint64();
            }
            next = reader.read!ubyte;
        }

        chat("  %s", packInfo.toString());

        if(next==0x0a) {
            decode_0A_PackStreamDigests();
            next = reader.read!ubyte;
        }

        expect(next==0x00);
    }
    /**
     * 0x07 UnpackInfo
     */
    void decode_07_UnpackInfo() {
        chat("0x07 - UnpackInfo");

        while(decodeProperty()) {}
    }
    /**
     * 0x08
     * [ 0x0D - NumUnPackStream ]
     * [ 0x09 - Size ]
     * [ 0x0A - CRC ]
     */
    void decode_08_SubStreamsInfo() {
        chat("0x08 - SubStreamsInfo");

        while(decodeProperty()) {}
    }
    void decode_0A_PackStreamDigests() {
        chat("0x0A - PackStreamDigests");

        expect(packInfo !is null);

        bool[] vec = decodeBoolVector(packInfo.numPackStreams);

        foreach(i; 0..packInfo.numPackStreams) {
            if(vec[i]) {
                auto crc = reader.read!uint;
                chat("crc = %s", crc);
            }
        }
    }
    /**
     * 0x0B Folder
     * numFolders
     * external
     * Folder (* numFolders)
     */
    void decode_0B_Folder() {
        chat("0x0B - Folder");

        auto numFolders = decodeUint64();
        chat("numFolders = %s", numFolders);

        auto external = reader.read!ubyte;

        if(external==0) {
            foreach(i; 0..numFolders) {
                chat("  Folder[%s]", i);

                Folder folder;
                ulong totalNumInStreams;
                ulong totalNumOutStreams;

                auto numCoders = decodeUint64();
                chat("    numCoders = %s", numCoders);

                foreach(c; 0..numCoders) {
                    chat("    Coder[%s]", c);

                    Coder coder;
                    coder.numInStreams = 1;
                    coder.numOutStreams = 1;

                    auto b = reader.read!ubyte;
                    chat("      mainByte = %08b", b);

                    auto codecIdSize    = b&0xf;
                    auto isComplexCoder = 0 != (b&0x10);
                    auto hasAttributes  = 0 != (b&0x20);

                    // chat("      codecIdSize = %s", codecIdSize);
                    // chat("      isComplex   = %s", isComplexCoder);
                    // chat("      hasAttribs  = %s", hasAttributes);

                    ubyte[] codecIds = reader.readArray!ubyte(codecIdSize);
                    //chat("      codecIds = %s", codecIds);

                    foreach(j; 0..codecIdSize) {
                        coder.methodId |= cast(ulong)codecIds[codecIdSize-1-j] << (8*j);
                    }
                    //chat("      methodId = %s (%x)", coder.methodId, coder.methodId);

                    if(coder.methodId != MethodID.LZMA) unsupported("Method %x".format(coder.methodId));

                    if(isComplexCoder) {
                        coder.numInStreams  = decodeUint64();
                        coder.numOutStreams = decodeUint64();
                    }
                    if(hasAttributes) {
                        auto propsSize = decodeUint64();
                        //chat("      propsSize = %s", propsSize);

                        coder.props = reader.readArray!ubyte(propsSize);
                        //chat("      props = %s", coder.props);
                    }
                    // chat("      numInStreams = %s", coder.numInStreams);
                    // chat("      numOutStreams = %s", coder.numOutStreams);

                    folder.coders ~= coder;

                    totalNumInStreams += coder.numInStreams;
                    totalNumOutStreams += coder.numOutStreams;
                } // coders

                ulong numBindPairs = totalNumOutStreams -1;
                chat("      numBindPairs = %s", numBindPairs);

                if(numBindPairs > 0) unsupported("numBindPairs > 0");

                ulong numPackStreams = totalNumInStreams - numBindPairs;
                chat("      numPackStreams = %s", numPackStreams);

                if(numPackStreams==1) {
                    auto k = 0;
                    for(k = 0; k<totalNumInStreams; k++) {

                    }
                    folder.packStreams ~= 0;
                } else {
                    unsupported("numPackStreams > 1");
                }

                folders ~= folder;
            }

        } else unsupported("external != 0");
    }
    /**
     * 0x0C
     * sizes
     */
    void decode_0C_CodersUnpackSize() {
        chat("0x0C - CodersUnpackSize");

        foreach(ref f; folders) {
            ulong size = decodeUint64();
            f.unpackedSizes ~= size;

            chat("    folder = %s", f);
        }
    }
    void decode_17_EncodedHeader() {
        chat("0x17 - EncodedHeader");

        chat("start pos = %s", reader.position);

        while(decodeProperty()) {}

        chat("pos = %s", reader.position);


    }
    bool decodeProperty(ubyte expecting = 0) {
        auto prop = reader.read!ubyte;
        chat("prop = %s", prop);
        if(expecting!=0) expect(prop==expecting);

        switch(prop) {
            case 0x00: return false;
            case 0x01: decode_01_Header(); break;
            case 0x02: decode_02_ArchiveProperties(); break;
            case 0x04: decode_04_MainStreamsInfo(); break;
            case 0x05: decode_05_FilesInfo(); break;
            case 0x06: decode_06_PackInfo(); break;
            case 0x07: decode_07_UnpackInfo(); break;
            case 0x08: decode_08_SubStreamsInfo(); break;
            case 0x0a: decode_0A_PackStreamDigests(); break;
            case 0x0b: decode_0B_Folder(); break;
            case 0x0c: decode_0C_CodersUnpackSize(); break;
            case 0x17: decode_17_EncodedHeader(); break;
            default:
                throw new Error("Unhandled property %s".format(prop));
        }
        return true;
    }
    ulong decodeUint64() {
        import core.bitop : bsr;

        ulong a     = reader.read!ubyte;
        uint b      = (~cast(uint)a)&0xff;
        uint bitPos = bsr(b);

        switch(bitPos) {
            case 7:
                // 0xxxxxxx (0-127)
                return (a&0b0111_1111);
            case 6:
                // 10xxxxxx (128-16383)
                return ((a&0b0011_1111) << 8) + reader.read!ubyte;
            case 5:
                // 110xxxxx (16384 - 2,097,151)
                return ((a&0b0001_1111) << 16) + reader.read!ushort;
            case 4:
                // 1110xxxx
                return ((a&0b0000_1111) << 24) +
                        (cast(ulong)reader.read!ubyte) +
                        (cast(ulong)reader.read!ubyte<<8) +
                        (cast(ulong)reader.read!ubyte<<16);
                        // (cast(ulong)reader.read!ubyte<<16) +
                        // (cast(ulong)reader.read!ubyte<<8) +
                        // (cast(ulong)reader.read!ubyte);
            case 3:
                // 11110xxx
                return ((a&0b0000_0111) << 32) + (reader.read!uint);
            case 2:
                // 111110xx
                return ((a&0b0000_0011) << 40) + (reader.read!ubyte) + (cast(ulong)reader.read!uint<<8);
            case 1:
                // 1111110x
                return ((a&0b0000_0001) << 48) + (reader.read!ushort) + (cast(ulong)reader.read!uint<<16);
            case 0:
                // 11111110
                return reader.read!ushort + (cast(ulong)reader.read!ubyte<<16) + (cast(ulong)reader.read!uint<<24);
            default:
                return reader.read!ulong;
        }
    }
    bool[] decodeBoolVector(ulong numItems) {
        auto allAreDefined = reader.read!ubyte != 0;
        bool[] vec = new bool[numItems];
        if(allAreDefined) {
            vec[] = true;
        } else {
            ubyte mask = 0;
            ubyte b    = 0;

            foreach(i; 0..numItems) {
                if(mask==0) {
                    b    = reader.read!byte;
                    mask = cast(ubyte)0x80;
                }
                vec[i] = cast(bool)(((b & mask) != 0) ? true : false);
                mask >>= 1;
            }
        }
        return vec;
    }
}