module resources.image.png.PNGReader;

import resources.all;
import resources.image.png.png_common;

import core.bitop               : bswap;
import std.algorithm.iteration  : filter, map;
import std.range                : join;
import std.string               : fromStringz;

final class PNGReader {
public:
    PNG read(string filename) {
        chat("Reading PNG '%s'", filename);

        auto png   = new PNG();
        auto file = File(filename, "rb");

        ubyte[8] sig;
        file.rawRead(sig);

        throwIf(sig[0]!=0x89 || sig[1]!='P' || sig[2]!='N' || sig[3]!='G', "Magic number not found");

        Chunk[] chunks;

        while(!file.eof) {
            auto ch = readChunk(file);
            chunks ~= ch;
            if(cast(IEND)ch) break;
        }

        throwIf(chunks[0].name!="IHDR", "This does not seem to be a valid PNG file");
        throwIf(chunks[$-1].name!="IEND", "This does not seem to be a valid PNG file");

        IHDR ihdr = cast(IHDR)chunks[0];

        png.width  = ihdr.width;
        png.height = ihdr.height;

        // colourType 2 = RGB, 3 = RGB, 6 = RGBA
        png.bytesPerPixel = ihdr.colourType==6 ? 4 : 3;

        png.data = unfilter(png, chunks, decompress(chunks));

        return png;
    }
private:
    Chunk readChunk(ref File f) {
        ubyte[8] bbuf;
        f.rawRead(bbuf);

        uint* p = cast(uint*)bbuf.ptr;

        uint length = bswap(*p);
        string name = cast(string)bbuf[4..$].idup;

        ubyte[] data;
        data.length = length;
        chat("%s: (%s bytes)", name, length);
        if(length>0) {
            f.rawRead(data);
        }

        uint[1] crc;
        f.rawRead(crc);

        switch(name) {
            case "IHDR" : return readIHDR(name, data);
            case "IDAT" : return readIDAT(name, data);
            case "sRGB" : return readsRGB(name, data);
            case "bKGD" : return readbKGD(name, data);
            case "pHYs" : return readpHYs(name, data);
            case "tIME" : return readtIME(name, data);
            case "tEXt" : return readtEXt(name, data);
            case "gAMA" : return readgAMA(name, data);
            case "cHRM" : return readcHRM(name, data);
            case "iCCP" : return readiCCP(name, data);
            case "iTXt" : return readiTXt(name, data);
            case "PLTE" : return readPLTE(name, data);
            case "IEND" : return readIEND(name);
            default : throw new Error("Header %s not supported".format(name));
        }
        assert(false);
    }
    IHDR readIHDR(string name, ubyte[] bytes) {
        if(bytes.length!=13) throw new Error("IHDR incorrect length");
        IHDR c = new IHDR;
        c.name = name;

        uint* iptr = cast(uint*)bytes.ptr;

        c.width  = bswap(iptr[0]);
        c.height = bswap(iptr[1]);
        c.bitDepth = bytes[8];
        c.colourType = bytes[9];
        c.compressionMethod = bytes[10];
        c.filterMethod = bytes[11];
        c.interlaceMethod = bytes[12];

        // colourType 2 = truecolour
        // colourType 3 = indexed colour (requires PLTE chunk)
        // colourType 6 = truecolour with alpha

        chat("%s", c);

        throwIf(c.compressionMethod!=0, "Only compression method 0 supported");
        throwIf(c.filterMethod!=0, "Only filter method 0 supported");
        throwIf(c.interlaceMethod!=0, "Interlacing not supported");
        throwIf(c.bitDepth!=8, "Only bit depth 8 supported (This is %s)".format(c.bitDepth));
        throwIf(!c.colourType.isOneOf(2,3,6), "Unsupported IHDR.colorType %s".format(c.colourType));
        
        chat("  [%s,%s] Colourtype %s", c.width, c.height, c.colourType);
        return c;
    }
    IEND readIEND(string name) {
        IEND c = new IEND;
        c.name = name;
        return c;
    }
    IDAT readIDAT(string name, ubyte[] bytes) {
        IDAT c = new IDAT;
        c.name = name;
        c.data = bytes.dup;
        return c;
    }
    sRGB readsRGB(string name, ubyte[] bytes) {
        sRGB c = new sRGB;
        c.name = name;
        c.intent = bytes[0];
        chat("  intent: %s", c.intent);
        return c;
    }
    bKGD readbKGD(string name, ubyte[] bytes) {
        bKGD c = new bKGD;
        c.name = name;
        c.r = (bytes[0]<<8) | bytes[1];
        c.g = (bytes[2]<<8) | bytes[3];
        c.b = (bytes[4]<<8) | bytes[5];
        chat("  Bgcolour %02x%02x%02x", c.r,c.g,c.b);
        return c;
    }
    pHYs readpHYs(string name, ubyte[] bytes) {
        pHYs c = new pHYs;
        c.name = name;

        uint* p = cast(uint*)bytes.ptr;
        c.xaxisPPU = bswap(p[0]);
        c.yaxisPPU = bswap(p[1]);
        c.unit = bytes[8];
        chat("  xaxisPPU: %s yaxisPPU: %s unit: %s", c.xaxisPPU, c.yaxisPPU, c.unit);
        return c;
    }
    tIME readtIME(string name, ubyte[] bytes) {
        tIME c = new tIME;
        c.name = name;
        c.year = (bytes[0]<<8) | bytes[1];
        c.month = bytes[2];
        c.day   = bytes[3];
        c.hour  = bytes[4];
        c.minute = bytes[5];
        c.second = bytes[6];
        return c;
    }
    tEXt readtEXt(string name, ubyte[] bytes) {
        tEXt c = new tEXt;
        c.name = name;
        char* p = cast(char*)bytes.ptr;
        c.keyword = cast(string)fromStringz(p);
        c.value   = cast(string)p[c.keyword.length+1..bytes.length];
        chat("  '%s' = '%s'", c.keyword, c.value);
        return c;
    }
    gAMA readgAMA(string name, ubyte[] bytes) {
        gAMA c = new gAMA;
        c.name = name;
        uint* p = cast(uint*)bytes.ptr;
        c.gamma = bswap(*p);
        chat("  %s", c.gamma);
        return c;
    }
    cHRM readcHRM(string name, ubyte[] bytes) {
        cHRM c = new cHRM;
        c.name = name;
        uint* p = cast(uint*)bytes.ptr;
        c.whitePointX = bswap(p[0]);
        c.whitePointY = bswap(p[1]);
        c.redX        = bswap(p[2]);
        c.redY        = bswap(p[3]);
        c.greenX      = bswap(p[4]);
        c.greenY      = bswap(p[5]);
        c.blueX       = bswap(p[6]);
        c.blueY       = bswap(p[7]);
        return c;
    }
    iCCP readiCCP(string name, ubyte[] bytes) {
        iCCP c = new iCCP;
        c.name = name;
        char* p = cast(char*)bytes.ptr;
        c.profileName = cast(string)fromStringz(p);
        auto len = c.profileName.length;
        c.compressionMethod = bytes[len+1];
        c.compressedProfileData = bytes[len+2..$].dup;

        chat("  profile: '%s'", c.profileName);
        return c;
    }
    iTXt readiTXt(string name, ubyte[] bytes) {
        iTXt c = new iTXt;
        c.name = name;
        char* p = cast(char*)bytes.ptr;
        c.keyword = cast(string)fromStringz(p);
        auto len = c.keyword.length + 1;
        c.compressionFlag = bytes[len];
        c.compressionMethod = bytes[len+1];
        c.languageTag = cast(string)fromStringz(p+len+2);
        len += 2 + c.languageTag.length + 1;
        c.translatedKeyword = cast(string)fromStringz(p+len);
        len += c.translatedKeyword.length+1;
        c.text = cast(string)p[len..bytes.length];

        chat("  Keyword: '%s' lang: '%s' trans: '%s'", c.keyword, c.languageTag, c.translatedKeyword);
        chat("  Text: '%s'", c.text);
        return c;
    }
    PLTE readPLTE(string name, ubyte[] bytes) {
        PLTE c = new PLTE;
        c.name = name;

        throwIf(bytes.length%3!=0, "PLTE length is not a multiple of 3");
        c.palette.length = bytes.length/3;

        foreach(i; 0..c.palette.length) {
            auto n = i*3;
            c.palette[i] = PLTE.RGB(bytes[n+0], bytes[n+1], bytes[n+2]);
        }

        return c;
    }
    ubyte[] decompress(Chunk[] chunks) {
        auto compressed =
            chunks.filter!(it=>it.name=="IDAT")
                  .map!(it=>(cast(IDAT)it).data)
                  .join();

        chat("  Compressed length   = %s", compressed.length);

        import std.zlib : uncompress;
        auto uncompressed = uncompress(compressed);

        chat("  Uncompressed length = %s", uncompressed.length);
        return cast(ubyte[])uncompressed;
    }
    /**
     *  https://www.w3.org/TR/PNG/#9FtIntro
     */
    ubyte[] unfilter(PNG png, Chunk[] chunks, ubyte[] filtered) {
        ubyte[] unfiltered;

        //bKGD bkgd = extractChunk!bKGD(chunks);

        IHDR ihdr = chunks[0].as!IHDR;

        int bpp = png.bytesPerPixel;

        if(ihdr.colourType == 3) {
            // Each src value is an index into the palette. 
            // We need to filter first before expanding to RGB
            bpp = 1;
        }

        int scanlineLen = png.width*bpp;
        long lines      = filtered.length / (scanlineLen+1);

        throwIf(lines!=png.height, "Expecting num lines to be %s but is %s".format(png.height, lines));
        
        unfiltered.length = lines*scanlineLen;

//        if(bkgd) {
//            // assuming rgba
//            for(auto i=0; i<unfiltered.length; i+=bpp) {
//                unfiltered[i]   = cast(ubyte)bkgd.r;
//                unfiltered[i+1] = cast(ubyte)bkgd.g;
//                unfiltered[i+2] = cast(ubyte)bkgd.b;
//            }
//        }

        uint filterBitmap;
        ubyte* src  = filtered.ptr;
        ubyte* dest = unfiltered.ptr;
        for(auto i=0; i<lines; i++) {

            ubyte getA(int n) {
                return n-bpp >= 0 ? dest[n-bpp] : 0;
            }
            ubyte getB(int n) {
                return i>0 ? *((dest+n)-scanlineLen) : 0;
            }
            ubyte getC(int n) {
                return (i>0 && n-bpp>=0) ?
                    *(((dest+n)-bpp)-scanlineLen) : 0;
            }
            uint paeth(int n) {
                return paethPredictor(getA(n), getB(n), getC(n));
            }
            void output(int n, int value) {
                dest[n] = cast(ubyte)value;
            }

            ubyte filter = *src++;
            switch(filter) {
                case 0 /*None*/ :
                    filterBitmap |= 1;
                    dest[0..scanlineLen] = src[0..scanlineLen];
                    break;
                case 1 /*Sub*/  :
                    filterBitmap |= 2;
                    for(int n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        output(n, (x + getA(n)) & 0xff);
                    }
                    break;
                case 2 /*Up*/ :
                    filterBitmap |= 4;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        output(n, (x + getB(n)) & 0xff);
                    }
                    break;
                case 3 /*Average*/ :
                    filterBitmap |= 8;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        output(n, (x + (getA(n)+getB(n)) / 2) & 0xff);
                    }
                    break;
                case 4 /*Paeth*/ :
                    filterBitmap |= 16;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        output(n, (x + paeth(n)) & 0xff);
                    }
                    break;
                default : throwIf(true, "Unsupported filter type %s", filter); break;
            }
            src  += scanlineLen;
            dest += scanlineLen;
        }
        chat("Filters used : %05b", filterBitmap);

        // For colour type 3 we now need to convert the result into RGB values from the palette
        if(ihdr.colourType == 3) {
            PLTE plte = extractChunk!PLTE(chunks);
            throwIf(plte is null, "Expected PLTE chunk");

            ubyte[] rgb = new ubyte[unfiltered.length*3];
            for(auto i=0; i<unfiltered.length; i++) {
                auto n = i*3;
                auto p = plte.palette[unfiltered[i]];
                rgb[n+0] = p.r;
                rgb[n+1] = p.g;
                rgb[n+2] = p.b;
            }
            return rgb;
        }

        return unfiltered;
    }
    T extractChunk(T)(Chunk[] chunks) {
        return cast(T)chunks.filter!(it=>cast(T)it !is null).front;
    }
}

