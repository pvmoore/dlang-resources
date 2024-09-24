module resources.image.r16;
/**
 *  Single red channel half floats.
 *
 *  Format:
 *  [0] uint = width
 *  [4] uint = height
 *  [8] data (width*height half floats)
 */
import resources.all;

final class R16 : Image {

    this(uint w, uint h) {
        this.width  = w;
        this.height = h;
        this.bytesPerPixel = 2;
        this.data.length = w*h*2;
    }

    void set(uint x, uint y, float value) {
        uint i   = x + y*width;
        auto ptr = cast(HalfFloat*)data.ptr;

        ptr[i] = HalfFloat(value);
    }
    float get(uint x, uint y) {
        uint i   = x + y*width;
        auto ptr = cast(HalfFloat*)data.ptr;
        return ptr[i].getFloat();
    }
    override void write(string filename) {
        scope f = File(filename, "wb");
        uint[2] header = [width,height];
        f.rawWrite(header);
        f.rawWrite(data);
    }

    static R16 read(string filename) {
        scope f  = File(filename, "rb");
        uint[2] header;
        f.rawRead(header);
        auto r16 = new R16(header[0], header[1]);
        r16.bytesPerPixel = 2;
        r16.data.length   = f.size-8;

        f.rawRead(r16.data);
        return r16;
    }
}

