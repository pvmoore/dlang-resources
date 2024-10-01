module resources.image.dds.DDS;

import resources.all;
import resources.image.dds.dds_common;
import resources.image.dds.DDSReader;

final class DDS : Image {
public:
    uint compressedFormat;  // VkFormat

    this(uint width, uint height, uint bytesPerPixel, ubyte[] data, uint compressedFormat) {
        this.width            = width;
        this.height           = height;
        this.bytesPerPixel    = bytesPerPixel;
        this.data             = data;
        this.compressedFormat = compressedFormat;
    }

    static DDS read(string filename) {
        return new DDSReader().read(filename);
    }
    override string toString() {
        string fmt = compressedFormat == VK_FORMAT_BC1_RGB_UNORM_BLOCK ? "BC1" :
                compressedFormat == VK_FORMAT_BC2_UNORM_BLOCK ? "BC2" :
                compressedFormat == VK_FORMAT_BC3_UNORM_BLOCK ? "BC3" :
                compressedFormat == DXGI_FORMAT.BC7_UNORM ? "BC7_UNORM" : 
                "UNKNOWN";
        return "DDS{%sx%s %s %s}".format(width, height, 
            bytesPerPixel==4 ? "RGBA" : bytesPerPixel==3 ? "RGB" : "A",
            fmt);
    }
}
