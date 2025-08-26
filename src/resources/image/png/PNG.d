module resources.image.png.PNG;

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
import resources.image.png.PNGReader;
import resources.image.png.PNGWriter;

final class PNG : Image {
public:
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

    void set(uint x, uint y, ubyte r, ubyte g, ubyte b, ubyte a) {
        uint i = (x + (y*width)) * bytesPerPixel;
        data[i+0] = r;
        data[i+1] = g;
        data[i+2] = b;
        if(bytesPerPixel>3) {
            data[i+3] = a;
        }
    }

    override void write(string filename) {
        new PNGWriter().write(this, filename);
    }

    static auto create_RGB(uint w, uint h) {
        return create_RGB(w, h, new ubyte[w*h*3]);
    }
    static auto create_RGBA(uint w, uint h) {
        return create_RGBA(w, h, new ubyte[w*h*4]);
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
        return new PNGReader().read(filename);
    }
    override string toString() {
        return "PNG{%sx%s %s}".format(width, height, bytesPerPixel==4 ? "RGBA" : bytesPerPixel==3 ? "RGB" : "A");
    }
}
