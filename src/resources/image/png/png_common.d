module resources.image.png.png_common;

import resources.all;

/**
 * http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html
 */

uint paethPredictor(int a, int b, int c) {
    import std.math : abs;
    int p  = a + b - c;
    int pa = abs(p - a);
    int pb = abs(p - b);
    int pc = abs(p - c);
    if(pa <= pb && pa <= pc) return a;
    if(pb <= pc) return b;
    return c;
} 

abstract class Chunk {
    string name;

    bool isCritical() { return name[0]!=name[0].toLower; }
    bool isPublic() { return name[1]!=name[1].toLower; }
}

private string stringOf(T)(T o) if(is(T : Chunk)) {
    import common.utils : getAllProperties, className;
    string s = "%s{".format(className!T);
    static foreach(i, p; getAllProperties!T) {
        if(i > 0) s ~= ",";
        s ~= "\n  %s: %s".format(p, __traits(getMember, o, p));
    }
    return s ~ "\n}";
}

final class IHDR : Chunk { 
    uint width;
    uint height;
    ubyte bitDepth;
    ubyte colourType;
    ubyte compressionMethod;
    ubyte filterMethod;
    ubyte interlaceMethod;

    override string toString() { return stringOf!IHDR(this); }
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
final class PLTE : Chunk {
    static struct RGB { ubyte r,g,b; } 
    RGB[] palette;
}
final class IEND : Chunk {
}
