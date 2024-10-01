module resources.image.dds.DDSReader;

import resources.all;
import resources.image.dds.dds_common;

/**
 * https://en.wikipedia.org/wiki/DirectDraw_Surface
 * https://learn.microsoft.com/en-gb/windows/win32/direct3ddds/dx-graphics-dds-pguide
 * https://en.wikipedia.org/wiki/S3_Texture_Compression
 *
 * BC7 specific:
 * https://learn.microsoft.com/en-us/windows/win32/direct3d11/bc7-format#about-bc7dxgi_format_bc7
 *
 * To convert images to DDS format you can use the Microsoft texconv utility:
 * eg. 
 * ```
 *   texconv.exe -m 1 -f BC7_UNORM logo.png
 * ```
 * This assumes you don't want any mip maps. 
 */

final class DDSReader {
public:
    DDS read(string filename) {
        chat("Reading DDS '%s'", filename);

        this.reader = new FileByteReader(filename);

        readMagic();
        readHeader();

        if(header.format.flags == DDPF.FOURCC && header.format.fourCC == FOURCC.DX10) {
            readDXT10Header();
        }

        switch(header.format.fourCC) {
            case FOURCC.DXT1 :
                return readCompressed(8, VK_FORMAT_BC1_RGB_UNORM_BLOCK);
            case FOURCC.DXT3 :
                log("WARN: Prefer DXT5 over DXT3 for RGBA images");
                return readCompressed(16, VK_FORMAT_BC2_UNORM_BLOCK);
            case FOURCC.DXT5 :
                return readCompressed(16, VK_FORMAT_BC3_UNORM_BLOCK);
            case FOURCC.DX10:
                return readCompressed(16, header10.dxgiFormat);
            default :
                bail("Format not supported: %s".format(header.format));
                break;
        }

        return null;
    }
private:
    FileByteReader reader;
    DDS_HEADER header;
    DDS_HEADER_DXT10 header10;
    
    void bail(string msg = null) {
        throwIf(true, msg ? msg : "This is not a valid DDS file");
    }
    void readMagic() {
        auto magic = reader.read!uint;
        if(magic!=0x20534444) bail("Magic bytes are not correct");
    }
    void readHeader() {
        DDS_HEADER h = {
            size         : reader.read!uint,
            flags        : reader.read!uint.as!DDSD,
            height       : reader.read!uint,
            width        : reader.read!uint,
            pitch        : reader.read!uint,
            depth        : reader.read!uint,
            mipMapLevels : reader.read!uint,
            format       : readPixelFormat(reader.skip(11*4)),
            caps         : reader.read!uint.as!DDSCAPS,
            caps2        : reader.read!uint.as!DDSCAPS2
        };
        reader.skip(3*4);
        throwIf(reader.position != 128);
        if(h.size!=124) bail("DDS_HEADER.size should be 124");
        if(h.caps != DDSCAPS.TEXTURE) bail("Only TEXTURE caps supported");
        if(h.caps2 != 0) bail("Cubemaps or volume textures are not supported");
        this.header = h;
        chat("%s", h);
    }
    void readDXT10Header() {
        DDS_HEADER_DXT10 h = {
            dxgiFormat        : reader.read!uint.as!DXGI_FORMAT,
            resourceDimension : reader.read!uint.as!D3D10_RESOURCE_DIMENSION,
            miscFlag          : reader.read!uint,
            arraySize         : reader.read!uint,
            miscFlags2        : reader.read!uint
        };
        this.header10 = h;
        chat("%s", h);
    }
    DDSPixelFormat readPixelFormat(ByteReader r) {
        DDSPixelFormat f = {
            size        : reader.read!uint,
            flags       : reader.read!uint.as!DDPF,
            fourCC      : reader.read!uint.as!FOURCC,
            RGBBitCount : reader.read!uint,
            RBitMask    : reader.read!uint,
            GBitMask    : reader.read!uint,
            BBitMask    : reader.read!uint,
            ABitMask    : reader.read!uint
        };
        if(f.size!=32) bail("DDSPixelFormat.size should be 32");
        if((f.flags & DDPF.FOURCC)==0) bail("Expecting a fourcc");
        if((f.flags & DDPF.ALPHAPIXELS) != 0) bail("Unsupported ALPHAPIXELS");
        return f;
    }
    DDS readCompressed(uint blockBytes, uint compressedFormat) {
        auto width        = header.width;
        auto height       = header.height;
        auto bitsPerPixel = 1;

        auto size = maxOf(4, width)/4 * maxOf(4, height)/4 * blockBytes;

        auto mipMapCount = header.flags.isSet(DDSD.MIPMAPCOUNT) ? header.mipMapLevels : 1;

        if(mipMapCount!=1) bail("Mip maps are not yet implemented");

        if(reader.remaining()!=size) bail("Expecting %s bytes remaining".format(size));

        ubyte[] data = reader.readArray!ubyte(reader.remaining());

        return new DDS(width, height, bitsPerPixel, data, compressedFormat);
    }
}
