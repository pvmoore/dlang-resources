module resources.image.image;

import resources.all;
import resources.image.converter;

/**
 * Todo - This can be a simple struct. There is no benefit to having this as an extendable class.
 *        In fact, it would be much easier to use if it was a simple struct.
 */
abstract class Image {
public:
    uint width;
    uint height;
    uint bytesPerPixel;
    ubyte[] data; // width*height*bytesPerPixel bytes

    static struct ReadOptions {
        bool forceRGBToRGBA = false;
    }

    final PNG getPNG() {
        if(this.isA!PNG) return this.as!PNG;
        auto b = new PNG;
        b.width = width;
        b.height = height;
        b.bytesPerPixel = bytesPerPixel;
        b.data = data.dup;
        return b;
    }

    void addAlphaChannel(ubyte a) {
        if(bytesPerPixel!=3) return;
        throwIfNot(this.isA!PNG || this.isA!BMP, "Unsupported operation");

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

    static Image read(string filename, ReadOptions options = ReadOptions()) {
        string ext = filename.extension.toLower;
        Image img;
        switch(ext) {
            case ".png" :
                img = PNG.read(filename);
                break;
            case ".bmp" :
                img = BMP.read(filename);
                break;
            case ".r32":
                img = R32.read(filename);
                break;
            case ".dds":
                img = DDS.read(filename);    
                break;
            case ".jpg":
            case ".jpeg":
            case ".jfif":
                img = JPEG.read(filename);
                // For now, convert this to a PNG so that we can do useful things with it.
                img = img.getPNG();
                break;
            default :
                throwIf(true, "Unable to read image file with extension '%s'", ext);
        }
        if(options.forceRGBToRGBA) {

            img.addAlphaChannel(255);
        }
        return img;
    }
    void write(string filename) {
        throwIf(true, "write is not yet supported for this Image type");
    }

    final void writePNG(string filename) {
        PNG png = this.as!PNG;
        if(!png) {
            png = new PNG;
            png.width = width;
            png.height = height;
            png.bytesPerPixel = bytesPerPixel;
            png.data = data.dup;
        }
        png.write(filename);
    }
}

