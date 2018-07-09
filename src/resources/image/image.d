module resources.image.image;
/**
 *
 */
import resources.all;
import resources.image.converter;

abstract class Image {
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
            default :
                throw new Exception("Unable to read image file with extension '%s'".format(ext));
        }
        assert(false);
    }
}

