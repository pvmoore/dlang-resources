module resources.image.png;
 /**
  *  https://www.w3.org/TR/PNG/
  *
  *  Only 8 bpp formats can be loaded (RGB or RGBA).
  *
  *  Data is stored internally as either RGB888 or RGBA8888
  *  and from top-left to bottom-right:
  *  eg.
  *  0--- x+
  *  |
  *  |
  *  y+
  */
import resources.all;
import std.uni : toLower;
import core.bitop : bswap;
import std.zlib : uncompress;
import std.algorithm.iteration : filter, map;
import std.range : array, join;
import std.string : fromStringz;

final class PNG : Image {

    BMP getBMP() {
        auto b = new BMP;
        b.width = width;
        b.height = height;
        b.bytesPerPixel = bytesPerPixel;
        b.data = data.dup;
        return b;
    }
    /**
     *  Convert RGBA to a single alpha channel
     */
    PNG getAlpha() {
        if(bytesPerPixel==1) return this;
        if(bytesPerPixel!=4) throw new Error("No alpha channel");
        PNG p = new PNG;
        p.width = width;
        p.height = height;
        p.bytesPerPixel = 1;
        p.data.length = width*height;

        for(auto s=0, d=0; s<data.length; d++, s+=4) {
            p.data[d] = data[s+3];
        }
        return p;
    }
    /**
     *  Convert RGB or RGBA to a single red channel
     */
    PNG getRed() {
        if(bytesPerPixel==1) return this;
        PNG p = new PNG;
        p.width  = width;
        p.height = height;
        p.bytesPerPixel = 1;
        p.data.length = width*height;

        for(auto s=0, d=0; s<data.length; d++, s+=4) {
            p.data[d] = data[s+0];
        }
        return p;
    }
    void addAlphaChannel(ubyte a) {
        if(bytesPerPixel!=3) return;
        bytesPerPixel = 4;
        ubyte[] data2 = new ubyte[width*height*4];
        ubyte* s = data.ptr;
        ubyte* d  = data2.ptr;
        foreach(y; 0..height)
        foreach(x; 0..width) {
            d[0] = s[0];
            d[1] = s[1];
            d[2] = s[2];
            d[3] = a;
            s+=3;
            d+=4;
        }
        data = data2;
    }

    static auto create_RGB(uint w, uint h, ubyte[] data) {
        expect(w*h*3==data.length);
        auto png = new PNG;
        png.bytesPerPixel = 3;
        png.width         = w;
        png.height        = h;
        png.data          = data;
        return png;
    }
    static auto create_RGBA(uint w, uint h, ubyte[] data) {
        expect(w*h*4==data.length);
        auto png = new PNG;
        png.bytesPerPixel = 4;
        png.width         = w;
        png.height        = h;
        png.data          = data;
        return png;
    }

    static PNG read(string filename) {
        chat("Reading PNG '%s'", filename);
        try{
            auto png   = new PNG();
            scope file = File(filename, "rb");

            ubyte[8] sig;
            file.rawRead(sig);

            if(sig[0]!=0x89 || sig[1]!='P' || sig[2]!='N' || sig[3]!='G') {
                throw new Error("");
            }

            Chunk[] chunks;

            while(!file.eof) {
                auto ch = readChunk(file);
                chunks ~= ch;
                if(cast(IEND)ch) break;
            }

            if(chunks[0].name!="IHDR") {
                throw new Error("");
            }
            if(chunks[$-1].name!="IEND") {
                throw new Error("");
            }

            IHDR ihdr = cast(IHDR)chunks[0];

            png.width  = ihdr.width;
            png.height = ihdr.height;
            png.bytesPerPixel = ihdr.colourType==6 ? 4 : 3;
            png.data   = unfilter(png, chunks, decompress(chunks));


            chat("PNG loaded");
            return png;
        }catch(Error e) {
            e.msg = "PNG file error '%s': ".format(filename) ~ e.msg;
            throw e;
        }
    }
private:
    static Chunk readChunk(ref File f) {
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
            case "IEND" : return readIEND(name);
            default : throw new Error("Header %s not supported".format(name));
        }
        assert(false);
    }
    static IHDR readIHDR(string name, ubyte[] bytes) {
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
        // colourType 6 = truecolour with alpha

        if(c.compressionMethod!=0) {
            throw new Error("Only compression method 0 supported");
        }
        if(c.filterMethod!=0) {
            throw new Error("Only filter method 0 supported");
        }
        if(c.interlaceMethod!=0) {
            throw new Error("Interlacing not supported");
        }
        if(c.bitDepth!=8) {
            throw new Error("Only bit depth 8 supported (This is %s)".format(c.bitDepth));
        }
        if(c.colourType!=2 && c.colourType!=6) {
            throw new Error("Only truecolour supported (This is %s)".format(c.colourType));
        }
        chat("  [%s,%s] Colourtype %s", c.width, c.height, c.colourType);
        return c;
    }
    static IEND readIEND(string name) {
        IEND c = new IEND;
        c.name = name;
        return c;
    }
    static IDAT readIDAT(string name, ubyte[] bytes) {
        IDAT c = new IDAT;
        c.name = name;
        c.data = bytes.dup;
        return c;
    }
    static sRGB readsRGB(string name, ubyte[] bytes) {
        sRGB c = new sRGB;
        c.name = name;
        c.intent = bytes[0];
        chat("  intent: %s", c.intent);
        return c;
    }
    static bKGD readbKGD(string name, ubyte[] bytes) {
        bKGD c = new bKGD;
        c.name = name;
        c.r = (bytes[0]<<8) | bytes[1];
        c.g = (bytes[2]<<8) | bytes[3];
        c.b = (bytes[4]<<8) | bytes[5];
        chat("  Bgcolour %02x%02x%02x", c.r,c.g,c.b);
        return c;
    }
    static pHYs readpHYs(string name, ubyte[] bytes) {
        pHYs c = new pHYs;
        c.name = name;

        uint* p = cast(uint*)bytes.ptr;
        c.xaxisPPU = bswap(p[0]);
        c.yaxisPPU = bswap(p[1]);
        c.unit = bytes[8];
        chat("  xaxisPPU: %s yaxisPPU: %s unit: %s",
            c.xaxisPPU, c.yaxisPPU, c.unit);
        return c;
    }
    static tIME readtIME(string name, ubyte[] bytes) {
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
    static tEXt readtEXt(string name, ubyte[] bytes) {
        tEXt c = new tEXt;
        c.name = name;
        char* p = cast(char*)bytes.ptr;
        c.keyword = cast(string)fromStringz(p);
        c.value   = cast(string)p[c.keyword.length+1..bytes.length];
        chat("  '%s' = '%s'", c.keyword, c.value);
        return c;
    }
    static gAMA readgAMA(string name, ubyte[] bytes) {
        gAMA c = new gAMA;
        c.name = name;
        uint* p = cast(uint*)bytes.ptr;
        c.gamma = bswap(*p);
        chat("  %s", c.gamma);
        return c;
    }
    static cHRM readcHRM(string name, ubyte[] bytes) {
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
        //chat("  ");
        return c;
    }
    static iCCP readiCCP(string name, ubyte[] bytes) {
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
    static iTXt readiTXt(string name, ubyte[] bytes) {
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

        chat("  Keyword: '%s' lang: '%s' trans: '%s'",
            c.keyword, c.languageTag, c.translatedKeyword);
        chat("  Text: '%s'", c.text);
        return c;
    }
    static ubyte[] decompress(Chunk[] chunks) {
        auto compressed =
            chunks.filter!(it=>it.name=="IDAT")
                  .map!(it=>(cast(IDAT)it).data)
                  .join();

        chat("  Compressed length   = %s", compressed.length);

        try{
            auto uncompressed = uncompress(compressed);

            chat("  Uncompressed length = %s", uncompressed.length);
            return cast(ubyte[])uncompressed;
        }catch(Exception e) {
            log("uncompress threw an exception: %s", e.msg);
            flushLog();
        }
        return [];
    }
    /**
     *  https://www.w3.org/TR/PNG/#9FtIntro
     */
    static ubyte[] unfilter(PNG png, Chunk[] chunks, ubyte[] filtered) {
        ubyte[] unfiltered;

        //bKGD bkgd = extractChunk!bKGD(chunks);

        int bpp         = png.bytesPerPixel;
        int scanlineLen = png.width*bpp;
        long lines      = filtered.length / (scanlineLen+1);

        if(lines!=png.height) {
            throw new Error("Expecting num lines to be %s".format(png.height));
        }
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
                import std.math : abs;
                int a = getA(n);
                int b = getB(n);
                int c = getC(n);
                int p  = a + b - c;
                int pa = abs(p - a);
                int pb = abs(p - b);
                int pc = abs(p - c);
                if(pa <= pb && pa <= pc) return a;
                if(pb <= pc) return b;
                return c;
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
                        dest[n] = cast(ubyte)((x + getA(n)) & 0xff);
                    }
                    break;
                case 2 /*Up*/ :
                    filterBitmap |= 4;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        dest[n] = cast(ubyte) ((x + getB(n)) & 0xff);
                    }
                    break;
                case 3 /*Average*/ :
                    filterBitmap |= 8;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        dest[n] = cast(ubyte)(
                            (x + (getA(n)+getB(n)) / 2) & 0xff
                        );
                    }
                    break;
                case 4 /*Paeth*/ :
                    filterBitmap |= 16;
                    for(auto n=0; n<scanlineLen; n++) {
                        ubyte x = src[n];
                        dest[n] = cast(ubyte)((x + paeth(n)) & 0xff);
                    }
                    break;
                default : throw new Error("Unsupported filter type %s".format(filter));
            }
            src  += scanlineLen;
            dest += scanlineLen;
        }
        chat("Filters used : %05b", filterBitmap);

        return unfiltered;
    }
    static T extractChunk(T)(Chunk[] chunks) {
        return cast(T)chunks.filter!(it=>cast(T)it !is null).front;
    }
}
//============================================================
private:

abstract class Chunk {
    string name;

    bool isCritical() { return name[0]!=name[0].toLower; }
    bool isPublic() { return name[1]!=name[1].toLower; }
}
final class IHDR : Chunk {
    uint width;
    uint height;
    ubyte bitDepth;
    ubyte colourType;
    ubyte compressionMethod;
    ubyte filterMethod;
    ubyte interlaceMethod;
}
final class IDAT : Chunk {
    ubyte[] data;
}
final class sRGB : Chunk {
    ubyte intent;
}
final class tEXt : Chunk {
    string keyword;
    string value;
}
final class iTXt : Chunk {
    string keyword;
    ubyte compressionFlag;
    ubyte compressionMethod;
    string languageTag;
    string translatedKeyword;
    string text;
}
final class bKGD : Chunk {
    // assumes colourTypes 2 or 6
    ushort r,g,b;
}
final class gAMA : Chunk {
    // gamma times 100_000
    // eg.  gamma of 1/2.2 would be stored as 45455
    uint gamma;
}
final class iCCP : Chunk {
    string profileName;
    ubyte compressionMethod;
    ubyte[] compressedProfileData;
}
final class cHRM : Chunk {
    // times 100000
    // eg. 0.3127 would be stored as 31270
    uint whitePointX;
    uint whitePointY;
    uint redX;
    uint redY;
    uint greenX;
    uint greenY;
    uint blueX;
    uint blueY;
}
final class pHYs : Chunk {
    uint xaxisPPU;  // pixels per unit
    uint yaxisPPU;
    ubyte unit;     // 0=unknown, 1=metre
}
final class tIME : Chunk {
    ushort year;
    ubyte month;
    ubyte day;
    ubyte hour;
    ubyte minute;
    ubyte second;
}
final class IEND : Chunk {
}
