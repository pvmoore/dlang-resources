module resources.image.jpeg.JFIFReader;

import resources.all;

import core.bitop               : byteswap, bswap;
import std.algorithm.iteration  : reduce;
import std.math                 : sqrt, cos, round;

import resources.image.jpeg.jpeg_bitstream;
import resources.image.jpeg.jpeg_huffman;

/**
 * https://en.wikipedia.org/wiki/JPEG_File_Interchange_Format
 * https://en.wikipedia.org/wiki/JPEG#JPEG_files
 * https://www.w3.org/Graphics/JPEG/itu-t81.pdf
 *
 * Supports sequential Baseline DCT only
 */
final class JFIFReader {
public:
    JPEG read(string filename) {
        this.filename = filename;

        // Note that the format is big-endian but we are reading little-endian and swapping the bytes.
        this.reader = new FileByteReader(filename);

        // SOI - Start of image marker
        ushort startOfImageMarker = reader.read!ushort.byteswap();
        throwIf(startOfImageMarker != MARKER_SOI, "%s is not a jpeg file", filename);
        
        while(!reader.eof()) {
            ushort marker = reader.read!ushort.byteswap();
            
            switch(marker) {
                case MARKER_APP0: readAPP0_FFE0(); break;
                case MARKER_APP1: 
                    throwIf(true, "EXIF is not supported");
                    break;
                case MARKER_APP11: readAPP11_FFEB(); break;
                case MARKER_APP12: readAPP12_FFEC(); break;
                case MARKER_APP14: readAPP14_FFEE(); break;
                case MARKER_COM: readCOM_FFFE(); break;
                case MARKER_DQT: readDQT_FFDB(); break;
                case MARKER_SOF0: readSOF0_FFC0(); break;
                case MARKER_SOF1: 
                    throwIf(true, "Extended sequential DCT is not supported");
                    break;
                case MARKER_SOF2:
                    throwIf(true, "Progressive DCT is not supported");
                    break;
                case MARKER_SOF3:
                    throwIf(true, "Lossless (sequential) is not supported");
                    break;        
                case MARKER_DHT: readDHT_FFC4(); break;
                case MARKER_SOS: readSOS_FFDA(); break;
                default: throwIf(true, "Unhandled marker: %x @ pos %s", marker, reader.position-2);
            }
        }

        JPEG jpeg = new JPEG;
        jpeg.width = width;
        jpeg.height = height;
        jpeg.bytesPerPixel = 3;
        jpeg.data = pixels;

        return jpeg;
    }
private:
    enum {
        MARKER_SOF0    = 0xffc0,        // baseline DCT start of frame
        MARKER_SOF1    = 0xffc1,        // extended sequential DCT start of frame
        MARKER_SOF2    = 0xffc2,        // progressive DCT start of frame
        MARKER_SOF3    = 0xffc3,        // lossless (sequential) start of frame
        MARKER_DHT     = 0xffc4,        // define huffman table
        MARKER_SOI     = 0xffd8,        // start of image
        MARKER_EOI     = 0xffd9,        // end of image
        MARKER_SOS     = 0xffda,        // start of scan
        MARKER_DQT     = 0xffdb,        // define quantization table
        MARKER_APP0    = 0xffe0,        // application specific (JFIF)
        MARKER_APP1    = 0xffe1,        // application specific (EXIF)
        MARKER_APP11   = 0xffeb,        // application specific (unknown)
        MARKER_APP12   = 0xffec,        // application specific (picture info?)
        MARKER_APP14   = 0xffee,        // application specific (Adobe transform info?)
        MARKER_COM     = 0xfffe,        // comment
        JFIF           = 0x4649464a,    // 'JFIF' little endian
    }
    static const uint[64] ZIGZAG = [
        0,  1,  8, 16,  9,  2,  3, 10,
        17, 24, 32, 25, 18, 11,  4,  5,
        12, 19,	26, 33, 40, 48, 41, 34,
        27, 20, 13,  6,  7, 14, 21, 28,
        35, 42, 49, 56, 57, 50, 43, 36,
        29, 22, 15, 23, 30, 37, 44, 51,
        58, 59, 52, 45, 38, 31, 39, 46,
        53, 60, 61, 54, 47, 55, 62, 63];

    static const double[64] IDCT_TABLE = [
        0.707107,  0.707107,  0.707107,  0.707107,  0.707107,  0.707107,  0.707107,  0.707107,
        0.980785,  0.831470,  0.555570,  0.195090, -0.195090, -0.555570, -0.831470, -0.980785,
        0.923880,  0.382683, -0.382683, -0.923880, -0.923880, -0.382683,  0.382683,  0.923880,
        0.831470, -0.195090, -0.980785, -0.555570,  0.555570,  0.980785,  0.195090, -0.831470,
        0.707107, -0.707107, -0.707107,  0.707107,  0.707107, -0.707107, -0.707107,  0.707107,
        0.555570, -0.980785,  0.195090,  0.831470, -0.831470, -0.195090,  0.980785, -0.555570,
        0.382683, -0.923880,  0.923880, -0.382683, -0.382683,  0.923880, -0.923880,  0.382683,
        0.195090, -0.555570,  0.831470, -0.980785,  0.980785, -0.831470,  0.555570, -0.195090
    ]; 
    static struct Component {
        enum Id : ubyte {
            Y  = 1,
            Cb = 2,
            Cr = 3,
            I  = 4,
            Q  = 5
        }
        uint index;
        Id id;

        uint horiz; // horizontal sampling factor 
        uint vert;  // vertical sampling factor 
        uint horizStretch;
        uint vertStretch;

        uint qtIndex;
        uint dcTableIndex;
        uint acTableIndex;

        int dcCoefficient;
        int[64] coefficients;

        string toString() {
            return "Component([%s], id: %s, horiz: %s (%s), vert: %s (%s), qt: %s, dc: %s, ac: %s)"
                .format(index, id, horiz, horizStretch, vert, vertStretch, qtIndex, dcTableIndex, acTableIndex);
        }
    }

    string filename;
    FileByteReader reader;

    ubyte[64][4] quantizationTables;   
    JPEGHuffmanTable[2] DC_huffmanTables;     
    JPEGHuffmanTable[2] AC_huffmanTables;    
    Component[] components;            
    uint width;
    uint height;
    uint bytesPerPixel;
    ubyte[] pixels;

    uint maxVertSamples;
    uint maxHorizSamples;

    /**
     * Application Specific 0
     * 
     * ubyte[5] = "JFIF/0"
     * ubyte minorVersion
     * ubyte majorVersion
     * ubyte densityUnits
     * ushort xDensity
     * ushort yDensity
     * ubyte Xthumbnail
     * ubyte Ythumbnail
     * ubyte[Xthumbnail*Ythumbnail*3] thumbnailData
     */
    void readAPP0_FFE0() {
        auto length = reader.read!ushort.byteswap();
        chat("APP0 ------------------------------- pos: %s length: %s", reader.position-4, length);

        uint jfif = reader.read!uint;
        ubyte zero = reader.read!ubyte;
        throwIfNot(jfif == JFIF, "Expected APP0 to be 'JFIF' but is %x", jfif);
        throwIfNot(zero == 0, "Expected APP0 byte 5 to be 0 but is %s", zero);

        ubyte majorVersion = reader.read!ubyte;
        ubyte minorVersion = reader.read!ubyte;

        chat("JFIF version = %s.0%s", majorVersion, minorVersion);

        // 0 = no units, 1 = pixels per inch, 2 = pixels per cm
        ubyte densityUnits = reader.read!ubyte;
        ushort xDensity    = reader.read!ushort.byteswap();
        ushort yDensity    = reader.read!ushort.byteswap();
        ubyte Xthumbnail   = reader.read!ubyte;
        ubyte Ythumbnail   = reader.read!ubyte;

        chat("Density units = %s", densityUnits);
        chat("X density = %s", xDensity);
        chat("Y density = %s", yDensity);
        chat("Thumbnail size = %s x %s", Xthumbnail, Ythumbnail);

        if(Xthumbnail * Ythumbnail > 0) {
            todo("read the thumbnail");
        }
    }
    /**
     * Application Specific 1 (EXIF)
     *
     * ubyte[6] = "Exif\0\0"
     * ushort byteOrder              (TIFF header 0..1)
     * ushort magic (0x002a)         (TIFF header 2..3)
     * ulong offset (0x00000008)     (TIFF header 4..7)
     * ushort tag (0x010f)           (IFD entry 0..1)
     * ushort type (0x0002)          (IFD entry 2..3)
     * uint count (0x00000001)       (IFD entry 4..7)
     * uint valueOffset (0x0000000d) (IFD entry 8..11)
     */
    void readAPP1_FFE1() {
        auto length = reader.read!ushort.byteswap();
        chat("APP1 ------------------------------- pos: %s length: %s", reader.position-4, length);

        const exifExpected = "Exif\0\0".ptr.as!(ubyte*)[0..6];

        ubyte[6] exif = reader.readArray!ubyte(6);
        throwIfNot(exif == exifExpected, "Expected APP1 to be 'Exif\0\0' but is %s", exif);

        // 0x4949 (II) = little endian,
        // 0x4d4d (MM) = big endian
        ushort byteOrder = reader.read!ushort;
        chat("byteOrder = %04x", byteOrder);
        throwIfNot(byteOrder.isOneOf(0x4949, 0x4d4d), "Expected APP1 byteOrder but is %04x", byteOrder);

        throwIfNot(byteOrder == 0x4d4d, "Only big endian is supported");

        // magic 42 in the byte oder specified above
        ushort magic = reader.read!ushort.byteswap();
        throwIfNot(magic == 0x002a, "Expected APP1 magic but is %04x", magic);

        // offset (in bytes) of the first IFD (Image File Directory)
        uint offsetOfIFD = reader.read!uint.bswap();
        chat("offsetOfIFD = %s", offsetOfIFD);

        // IFD Entry (12 bytes)
        ushort tag = reader.read!ushort.byteswap();
        ushort type = reader.read!ushort.byteswap();
        uint count = reader.read!uint.bswap();
        uint valueOffset = reader.read!uint.bswap();
        chat("tag = %s, type = %s, count = %s, valueOffset = %s", tag, type, count, valueOffset);

        chat("position = %s", reader.position);
        todo();
    }
    /**
     * Application Specific 11
     *
     *
     */
    void readAPP11_FFEB() {
        auto length = reader.read!ushort.byteswap();
        chat("APP11 ----------------------------- pos: %s length: %s", reader.position-4, length);

        ubyte[] data = reader.readArray!ubyte(length-2);
        // chat("data = %s", data);
        // chat("data = %s", data.as!string);

        todo();
    }
    /**
     * Application Specific 12
     * Possible Adobe picture info
     */
    void readAPP12_FFEC() {
        auto length = reader.read!ushort.byteswap();
        chat("APP12 ----------------------------- pos: %s length: %s", reader.position-4, length);

        import std.utf;  

        ubyte[] data = reader.readArray!ubyte(length-2);

        chat("data = %s", data);
        chat("data = %s", data.as!string);
    }
    /**
     * Application Specific 14
     * Possible Adobe transform info
     */
    void readAPP14_FFEE() {
        auto length = reader.read!ushort.byteswap();
        chat("APP14 ----------------------------- pos: %s length: %s", reader.position-4, length);

        ubyte[] data = reader.readArray!ubyte(length-2);
        chat("data = %s", data);
        chat("data = %s", data.as!string);
    }
    /**
     * Comment
     */
    void readCOM_FFFE() {
        auto length = reader.read!ushort.byteswap();
        chat("COM ------------------------------- pos: %s length: %s", reader.position-4, length);

        ubyte[] comment = reader.readArray!ubyte(length-2);
        chat("Comment = '%s'", cast(string)comment);
    }
    /**
     * Start of Frame (Baseline DCT)
     *
     * ubyte precision
     * ushort height (num lines)
     * ushort width (samples per line)
     * ubyte numComponents  
     * ubyte[components*3] componentInfo
     */
    void readSOF0_FFC0() {
        uint length = reader.read!ushort.byteswap();
        chat("SOF0 ------------------------------- pos: %s length: %s", reader.position-4, length);

        ubyte precision = reader.read!ubyte;
        this.height = reader.read!ushort.byteswap();
        this.width = reader.read!ushort.byteswap();
        ubyte numComponents = reader.read!ubyte;
        chat("precision = %s", precision);
        chat("height = %s", height);
        chat("width = %s", width);
        chat("numComponents = %s", numComponents);

        throwIf(length != 8 + numComponents*3, "Expected length to be 8 + numComponents*3 but is %s", length);

        throwIfNot(numComponents.isOneOf(1,2,3,4), "Expected numComponents to be 1, 2, 3 or 4 but is %s", numComponents);

        // We only support 3 components
        throwIfNot(numComponents == 3, "Only 3 components are supported");

        this.components.length = numComponents;

        this.maxHorizSamples = 0;
        this.maxVertSamples  = 0;

        foreach(i; 0..numComponents) {
            auto id = reader.read!ubyte.as!(Component.Id);
            auto samplingFactor = reader.read!ubyte;
            auto qtIndex = reader.read!ubyte;

            uint horiz = samplingFactor >> 4;
            uint vert = samplingFactor & 0b1111;
            if(horiz > maxHorizSamples) maxHorizSamples = horiz;
            if(vert > maxVertSamples) maxVertSamples = vert;

            components[i] = Component(i.as!uint, id, horiz, vert, qtIndex, 0, 0);
            chat("%s", components[i]);

            throwIf(qtIndex > 3, "Quantization table %s not found", qtIndex);
            throwIf(!id.isOneOf(Component.Id.Y, Component.Id.Cb, Component.Id.Cr), "Only YCbCr is supported");
        }

        foreach(ref c; components) {
            c.horizStretch = maxHorizSamples / c.horiz;
            c.vertStretch = maxVertSamples / c.vert;
        }
    }
    /**
     * Define Quantization Table
     *
     * ubyte PqTq
     * ubyte[64] table
     */
    void readDQT_FFDB() {
        uint length = reader.read!ushort.byteswap();
        chat("DQT ------------------------------- pos: %s length: %s", reader.position-4, length);

        int remaining = length-2;

        // There can be multiple tables
        while(remaining > 0) {
            ubyte PqTq = reader.read!ubyte;

            // Precision (0 = 8bit, 1 = 16bit)
            uint Pq = PqTq >> 4;
            // Table index (0 to 3)
            uint Tq = PqTq & 0b1111;

            chat("precision = %s", Pq);
            chat("qtIndex   = %s", Tq);

            throwIfNot(Pq.isOneOf(0,1), "Expected Pq to be 0 or 1 but is %s", Pq);
            throwIfNot(Tq.isOneOf(0,1,2,3), "Expected Tq to be 0, 1, 2 or 3 but is %s", Tq);

            throwIfNot(Pq == 0, "Only 8-bit precision is supported");

            ubyte[64] qt = reader.readArray!ubyte(64);

            quantizationTables[Tq] = qt;

            // chat("Quantization Table:");
            // foreach(y; 0..8) {
            //     chat("% 2u % 2u % 2u % 2u % 2u % 2u % 2u % 2u", 
            //         qt[y*8+0], qt[y*8+1], qt[y*8+2], qt[y*8+3], qt[y*8+4], qt[y*8+5], qt[y*8+6], qt[y*8+7]);
            // }

            remaining -= (64 + 1);
            chat("remaining = %s", remaining);
        }
    }
    /**
     * Define Huffman Table
     *
     * ubyte TcTh
     * ubyte[16] counts
     * ubyte[counts.sum()] lengths
     */
    void readDHT_FFC4() {
        auto length = reader.read!ushort.byteswap();
        chat("DHT ------------------------------- pos: %s length: %s", reader.position-4, length);

        int remaining = length-2;

        // There can be multiple tables
        while(remaining > 0) {
            ubyte TcTh = reader.read!ubyte;

            // Table index (0 or 1)
            uint Th = TcTh & 0b1111;
            // Table class (0=DC, 1=AC)
            uint Tc = TcTh >> 4;
            chat("Tc = %s, Th = %s", Tc, Th);

            throwIfNot(Tc.isOneOf(0,1), "Expected DHT Tc to be 0 or 1 but is %s", Tc);
            throwIfNot(Th.isOneOf(0,1), "Expected DHT Th to be 0 or 1 but is %s", Th);

            ubyte[] counts = reader.readArray!ubyte(16);
            uint sum = counts.reduce!((a,b) => a+b);
            chat("Code lengths:");
            chat("  [ 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16]");
            chat("  [%02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s %02s]", 
                counts[0], counts[1], counts[2], counts[3], counts[4], counts[5], counts[6], counts[7], counts[8], counts[9], counts[10], counts[11], counts[12], counts[13], counts[14], counts[15]);

            ubyte[] lengths = reader.readArray!ubyte(sum);
            chat("Lengths:");
            chat("  %s", lengths);
            chat("  sum = %s", sum);

            JPEGHuffmanTable table = JPEGHuffmanTable(counts, lengths);

            if(Tc == 0) {
                DC_huffmanTables[Th] = table;
            } else {
                AC_huffmanTables[Th] = table;
            }

            remaining -= (16 + sum + 1);

            chat("remaining = %s", remaining);
        }
    }
    
    /**
     * Start of Scan
     *
     * ubyte Ns (number of components in scan)
     * ubyte[2*Ns] componentSpecs
     * ubyte Ss (start of spectral selection)
     * ubyte Se (end of spectral selection)
     * ubyte Ah (successive approximation bit position high)
     * ubyte Al (successive approximation bit position low)
     */
    void readSOS_FFDA() {
        uint length = reader.read!ushort.byteswap();
        chat("SOS ------------------------------- pos: %s length: %s", reader.position-4, length);

        // Number of components in scan
        ubyte Ns = reader.read!ubyte;
        throwIfNot(Ns.isOneOf(1,2,3,4), "Expected SOS Ns to be 1, 2, 3 or 4 but is %s", Ns);

        // We only support Ns == 3
        throwIfNot(Ns == components.length, "Expected SOS Ns to be %s but is %s", components.length, Ns);

        foreach(i; 0..Ns) {
            ubyte Cs   = reader.read!ubyte;
            ubyte TdTa = reader.read!ubyte;
            throwIfNot(Cs == i+1, "Expected Cs to be %s but is %s", i+1, Cs);

            // DC entropy coding table destination selector
            uint Td = TdTa >> 4;

            // AC entropy coding table destination selector
            uint Ta = TdTa & 0b1111;

            // Assert baseline specs
            throwIfNot(Td.isOneOf(0,1), "Expected Td to be 0 or 1 but is %s", Td);
            throwIfNot(Ta.isOneOf(0,1), "Expected Ta to be 0 or 1 but is %s", Ta);

            components[i].dcTableIndex = Td;
            components[i].acTableIndex = Ta;

            chat("..Component[%s] = %s", i, components[i]);
        }

        ubyte Ss = reader.read!ubyte;
        ubyte Se = reader.read!ubyte;
        ubyte AhAl = reader.read!ubyte;
        uint Ah = AhAl >> 4;
        uint Al = AhAl & 0b1111;
        chat("Ss = %s, Se = %s, Ah = %s, Al = %s", Ss, Se, Ah, Al);

        // Assert baseline specs
        throwIfNot(Ss == 0, "Expected Ss to be 0 but is %s", Ss);
        throwIfNot(Se == 63, "Expected Se to be 63 but is %s", Se);
        throwIfNot(Ah == 0, "Expected Ah to be 0 but is %s", Ah);
        throwIfNot(Al == 0, "Expected Al to be 0 but is %s", Al);

        chat("Summary:");
        foreach(i, t; quantizationTables) {
            chat("  QT[%s] = %s", i, t);
        }
        chat("  width  = %s", width);
        chat("  height = %s", height);
        chat("End of summary");

        // Fetch the scan data and remove 0xff00 sequences 
        BitStream bits = new BitStream(fetchScanData());

        uint MCUWidth  = 8 * maxHorizSamples;
        uint MCUHeight = 8 * maxVertSamples;
        double[] decodedData = new double[width * height * components.length];

        // Decode the MCUs 
        for(int y = 0; y < height; y += MCUHeight) {
            for(int x = 0; x < width; x += MCUWidth) {
                foreach(ref c; components) {
                    decodeMCUComponent(x, y, c, bits, decodedData);
                }
            }
        }

        this.bytesPerPixel = components.length.as!uint;
        this.pixels = convertToRGB(decodedData);
    }
    /**
     * Read the scan data until we reach a 0xFFnn marker. Dummy 0xFF00 markers are replaced with 0xFF
     */
    ubyte[] fetchScanData() {
        ubyte[] data = reader.readArray!ubyte(reader.remaining());
        ubyte[] data2; data2.reserve(data.length);

        for(int i = 0; i+1<data.length; i++) {
            ubyte b = data[i];
            if(b == 0xff) {
                ubyte b2 = data[i+1];
                if(b2 != 0) {
                    // Exit if we find a marker (this is probably 0xffd9)
                    chat("marker = 0x%04x", (b<<8)|b2);
                    break;
                }

                i++;
                data2 ~= 0xff;
            } else {
                data2 ~= b;
            }
        }
        chat("Scan data length = %s, (removed %s bytes)", data2.length, data.length-data2.length);
        return data2;
    }
    /**
     * Convert decoded data to RGB
     */
    ubyte[] convertToRGB(double[] decodedData) {
        ubyte clamp(double col) {
            return round(minOf(maxOf(col, 0.0), 255.99)).as!ubyte;
        }
        ubyte[3] convertYCbCr(double Y, double Cb, double Cr) {
            double R = Y + 1.402 * Cr;
            double G = Y - 0.34414 * Cb - 0.71414 * Cr;
            double B = Y + 1.772 * Cb;
            return [clamp(R+128), clamp(G+128), clamp(B+128)];
        }

        ubyte[] rgb = new ubyte[decodedData.length];
        for(int i = 0; i < decodedData.length; i += 3) {
            auto c = convertYCbCr(decodedData[i+0], decodedData[i+1], decodedData[i+2]);
            rgb[i+0] = c[0];
            rgb[i+1] = c[1];
            rgb[i+2] = c[2];
        }
        return rgb;
    }

    /**
     * Decode MCU component - Minimum Coded Unit
     * params:
     *   xOffset: current x position 
     *   yOffset: current y position 
     *   component: the current component 
     *   bits: bit stream
     */
    void decodeMCUComponent(int xOffset, int yOffset, ref Component component, BitStream bits, double[] decodedData) {

        ubyte[64] quantTable     = quantizationTables[component.qtIndex];
        JPEGHuffmanTable dcTable = DC_huffmanTables[component.dcTableIndex];
        JPEGHuffmanTable acTable = AC_huffmanTables[component.acTableIndex];
        
        void buildMatrix() {

            int decodeCoefficient(uint theBits, uint numBits) {
                return theBits >> (numBits-1) ? theBits : theBits.as!int - (1 << numBits) + 1;
            }

            // Reset all of the coefficients
            component.coefficients[] = 0;

            // DC coefficient
            ubyte numBits  = dcTable.read(bits);
            uint theBits   = bits.getNBits(numBits);
            int coeffDelta = decodeCoefficient(theBits, numBits);
            component.dcCoefficient += coeffDelta;
            component.coefficients[ZIGZAG[0]] = component.dcCoefficient * quantTable[0];

            // AC coefficients
            for(auto i = 1; i < 64; i++) {
                ubyte symbol = acTable.read(bits);
                //if(symbol == 0) break;

                uint skippedZeroes = symbol >> 4;
                uint size          = symbol & 0b1111;
                i += skippedZeroes;
                if(size == 0) {
                    if(skippedZeroes == 15) {
                        continue;
                    }
                    break;
                }

                throwIf(i >= 64, "i >= 64");

                theBits = bits.getNBits(size);
                int coeff = decodeCoefficient(theBits, size);
                component.coefficients[ZIGZAG[i]] = coeff * quantTable[i];
            }
        }

        // Decode the coefficients for this component
        foreach(v1; 0.. component.vert) {
            foreach(h1; 0..component.horiz) {

                int X = xOffset + h1*8;
                int Y = yOffset + v1*8;
              
                buildMatrix();

                // Write the decoded values to the destination 
                for(auto y = 0; (y < 8) && (Y+y < height); y++) {
                    for(auto x = 0; (x < 8) && (X+x < width); x++) {
                        
                        double idct() {
                            double sum = 0;
                            foreach(u; 0..8) {
                                foreach(v; 0..8) {
                                    sum += component.coefficients[v*8+u] * IDCT_TABLE[u*8+x] * IDCT_TABLE[v*8+y];
                                }
                            }
                            return sum / 4;
                        }

                        double value = idct();
                        uint pixelX = X + x * component.horizStretch;
                        uint pixelY = Y + y * component.vertStretch;

                        for(auto v = 0; (v < component.vertStretch) && (pixelY + v < height); v++) {
                            for(auto h = 0; (h < component.horizStretch) && (pixelX + h < width); h++) {

                                uint i = 3 * (pixelX + h + (pixelY + v)*width);
                                decodedData[i + component.index] = value;
                            }
                        }
                    }
                }  
            }
        }
    }
}
