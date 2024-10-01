module resources.image.image;
/**
 *
 */
import resources.all;
import resources.image.converter;

abstract class Image {
public:
    uint width;
    uint height;
    uint bytesPerPixel;
    ubyte[] data; // width*height*bytesPerPixel bytes

    static Image read(string filename) {
        string ext = filename.extension.toLower;
        switch(ext) {
            case ".png" :
                return PNG.read(filename);
            case ".bmp" :
                return BMP.read(filename);
            case ".r32":
                return R32.read(filename);
            case ".dds":
                return DDS.read(filename);    
            default :
                throw new Exception("Unable to read image file with extension '%s'".format(ext));
        }
        assert(false);
    }
    void write(string filename) {
        throw new Exception("write is not yet supported for this Image type");
    }
}

