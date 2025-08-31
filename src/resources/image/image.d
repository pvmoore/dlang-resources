module resources.image.image;

import resources.all;
import resources.image.converter;

abstract class Image {
public:
    uint width;
    uint height;
    uint bytesPerPixel;
    ubyte[] data; // width*height*bytesPerPixel bytes

    static struct ReadOptions {
        bool forceRGBToRGBA = false;
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

