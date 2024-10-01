module resources.image.png.PNGWriter;

import resources.all;
import resources.image.png.png_common;
import std.digest.crc : CRC32, crc32Of;

final class PNGWriter {
public:
    void write(PNG png, string filename) {
        // This needs to be big endian
        this.buf = new ArrayByteWriter(1024, false);
        this.png = png;

        writeMagic();
        writeIHDR();
        writeIDAT();
        writeIEND();

        auto file = File(filename, "wb");
        scope(exit) file.close();
        file.rawWrite(buf.getArray());
    }
private:
    ArrayByteWriter buf;
    PNG png;

    void writeMagic() {
        buf.writeArray!ubyte([cast(ubyte)0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a]);
    }
    /**
     * uint width;
     * uint height;
     * ubyte bitDepth;
     * ubyte colourType;
     * ubyte compressionMethod;
     * ubyte filterMethod;
     * ubyte interlaceMethod;
     */
    void writeIHDR() {
        ubyte bitDepth = 8;
        // colourType 2 = RGB
        // colourType 6 = RGBA
        ubyte colourType = png.bytesPerPixel == 3 ? 2 : 6;
        ubyte compressionMethod = 0;
        ubyte filterMethod = 0;
        ubyte interlaceMethod = 0;

        buf.write!uint(13);
        buf.writeArray!ubyte("IHDR".as!(ubyte[]));
        
        buf.write!uint(png.width);
        buf.write!uint(png.height);
        buf.write!ubyte(bitDepth);
        buf.write!ubyte(colourType);
        buf.write!ubyte(compressionMethod);
        buf.write!ubyte(filterMethod);
        buf.write!ubyte(interlaceMethod);

        buf.write!uint(calculateCRC(17));
    }
    void writeIEND() {
        buf.write!uint(0);
        buf.writeArray!ubyte("IEND".as!(ubyte[]));
        buf.write!uint(calculateCRC(4));
    }
    void writeIDAT() {
        import std.zlib : compress;

        chat("Writing data (%s bytes)", png.data.length);

        ubyte[] filtered = filter();
        ubyte[] compressed = compress(filtered, 9);

        chat("  filtered length %s bytes", filtered.length);
        chat("  compressed length %s bytes", compressed.length);

        buf.write!uint(compressed.length.as!uint);
        buf.writeArray!ubyte("IDAT".as!(ubyte[]));
        buf.writeArray!ubyte(compressed);
        buf.write!uint(calculateCRC(compressed.length.as!uint+4));
    }
    /**
     * https://www.w3.org/TR/PNG/#9FtIntro
     * http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html
     */
    ubyte[] filter() {
        int bpp         = png.bytesPerPixel;
        auto lineLength = png.width * png.bytesPerPixel;
        auto numLines = png.data.length / lineLength;
        ubyte[] dest = new ubyte[numLines*lineLength + numLines];
        ubyte* srcLinePtr = png.data.ptr;
        ubyte* prevSrcLinePtr;
        ubyte* destLinePtr = dest.ptr;
        uint line;

        // C  B
        // A [X]
        ubyte origX(int n) {
            return srcLinePtr[n];
        }
        ubyte origA(int n) {
            return n < bpp ? 0 : srcLinePtr[n-bpp];
        }
        ubyte origB(int n) {
            return prevSrcLinePtr is null ? 0 : prevSrcLinePtr[n];
        }
        ubyte origC(int n) {
            return n < bpp || prevSrcLinePtr is null ? 0 : prevSrcLinePtr[n-bpp];
        }
        uint paeth(int n) {
            return paethPredictor(origA(n), origB(n), origC(n));
        }
        
        /** None: Filt(x) = Orig(x) */
        uint _writeLineMethod0() {
            uint sum = 0;
            foreach(n; 0..lineLength) {
                ubyte v = origX(n);
                sum += msad(v);
                destLinePtr[n] = v;
            }
            return sum;
        }
        /** Sub: Filt(x) = Orig(x) - Orig(a) */
        uint _writeLineMethod1() {
            uint sum = 0;
            foreach(n; 0..lineLength) {
                ubyte v = ((origX(n) - origA(n)) & 0xff).as!ubyte;
                sum += msad(v);
                destLinePtr[n] = v;
            }
            return sum;
        }
        /** Up: Filt(x) = Orig(x) - Orig(b) */
        uint _writeLineMethod2() {
            if(line==0) return _writeLineMethod0();
            uint sum = 0;
            foreach(n; 0..lineLength) {
                ubyte v = ((origX(n) - origB(n)) & 0xff).as!ubyte;
                sum += msad(v);
                destLinePtr[n] = v;
            }
            return sum;
        }
        /** Average: Filt(x) = Orig(x) - floor((Orig(a) + Orig(b)) / 2) */
        uint _writeLineMethod3() {
            uint sum = 0;
            foreach(n; 0..lineLength) {
                ubyte v = ((origX(n) - ((origA(n) + origB(n)) / 2)) & 0xff).as!ubyte;
                sum += msad(v);
                destLinePtr[n] = v;
            }
            return sum;
        }
        /** Filt(x) = Orig(x) - PaethPredictor(Orig(a), Orig(b), Orig(c)) */
        uint _writeLineMethod4() {
            uint sum = 0;
            foreach(n; 0..lineLength) {
                ubyte v = (origX(n) - paeth(n)).as!ubyte;
                sum += msad(v);
                destLinePtr[n] = v;
            }
            return sum;
        }

        ubyte _selectLineFilter() {
            destLinePtr++;
            uint sum0 = _writeLineMethod0();
            uint sum1 = _writeLineMethod1();
            uint sum2 = _writeLineMethod2();
            uint sum3 = _writeLineMethod3();
            uint sum4 = _writeLineMethod4();

            uint lowest = sum0;
            ubyte selected = 0;
            if(sum1 < lowest) { lowest = sum1; selected = 1; }
            if(sum2 < lowest) { lowest = sum2; selected = 2; }
            if(sum3 < lowest) { lowest = sum3; selected = 3; }
            if(sum4 < lowest) { lowest = sum4; selected = 4; }

            destLinePtr--;
            return selected;
        }
        
        for(; line<numLines; line++) {
            // Select a filter type for this line
            auto filterType = _selectLineFilter();

            // Write the line filter type byte and move the dest pointer by 1 byte
            *destLinePtr++ = filterType;

            // Implement the filtering for this line
            switch(filterType) {
                case 0:
                    _writeLineMethod0();
                    break;
                case 1:
                    _writeLineMethod1();
                    break;
                case 2:
                    _writeLineMethod2();
                    break;  
                case 3:
                    _writeLineMethod3();
                    break;    
                case 4:
                    _writeLineMethod4();
                    break;         
                default: 
                    throwIf(true, "We shouldn't get here");
                    break;
            }

            // Move the pointers to the next line
            prevSrcLinePtr = srcLinePtr;
            srcLinePtr += lineLength;
            destLinePtr += lineLength;
        }
        return dest;
    }
    uint msad(uint v) {
        return v < 128 ? v : 256 - v;
    }
    uint calculateCRC(uint length) {
        auto array = buf.getArray();
        auto from = array.length-length;
        ubyte[4] crc = crc32Of(array[from..$]);
        //chat("crc = %s", array[from..$]);
        return *crc.ptr.as!(uint*);
    }
}
