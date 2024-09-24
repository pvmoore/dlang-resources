module resources.image.r32;
/**
 *  Single red channel float.
 *
 *  Format:
 *  [0] uint = width
 *  [4] uint = height
 *  [8] data (width*height floats)
 */
import resources.all;
import std.zlib : compress, uncompress;

final class R32 : Image {

    this(uint w, uint h) {
        this.width  = w;
        this.height = h;
        this.bytesPerPixel = 4;
        this.data.length = w*h*4;
    }

    void set(uint x, uint y, float value) {
        uint i   = x + y*width;
        auto ptr = cast(float*)data.ptr;
        ptr[i] = value;
    }
    float get(uint x, uint y) {
        uint i   = x + y*width;
        auto ptr = cast(float*)data.ptr;
        return ptr[i];
    }
    override void write(string filename) {
        scope f = File(filename, "wb");
        uint[2] header = [width,height];
        f.rawWrite(header);

        auto packed = compress(data, 9);
        f.rawWrite(packed);
    }

    static R32 read(string filename) {
        scope f  = File(filename, "rb");
        uint[2] header;
        f.rawRead(header);
        auto r32 = new R32(header[0], header[1]);
        r32.bytesPerPixel = 4;

        ubyte[] data = new ubyte[f.size-8];
        f.rawRead(data);
        r32.data = cast(ubyte[])uncompress(data);
        expect(r32.data.length==r32.width*r32.height*4);
        return r32;
    }

}

