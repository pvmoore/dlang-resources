module resources.image.dds;

import resources.all;

import core.sys.windows.windows;

/**
 * DXT
 *
 * https://en.wikipedia.org/wiki/DirectDraw_Surface
 * https://learn.microsoft.com/en-gb/windows/win32/direct3ddds/dx-graphics-dds-pguide
 * https://en.wikipedia.org/wiki/S3_Texture_Compression
 *
 * BC1 - (DXT1)
 *      RGB
 *      VK_FORMAT_BC1_RGB_UNORM_BLOCK
 *      Use this for images without alpha
 *
 * BC2 - (DXT2,DXT3)
 *      Don't use this one
 *
 * BC3 - (DXT4,DXT5)
 *      RGBA
 *      VK_FORMAT_BC3_UNORM_BLOCK
 *      Use this for images with alpha
 *
 * BC4, BC5 - (DirectX 10)
 *      BC4 is 1 channel greyscale 
 *      BC5 is 2 channel (normal maps?)
 *
 * BC6H, BC7 - (DirectX 11)
 *     BC6H is for RGB HDR (float16)
 *     BC7 is for RGB/RGBA 8 bit images (like BC3 but better)
 *
 */
final class DDS : Image {
private:
    this(uint width, uint height, uint bytesPerPixel, ubyte[] data, uint compressedFormat) {
        this.width = width;
        this.height = height;
        this.bytesPerPixel = bytesPerPixel;
        this.data = data;
        this.compressedFormat = compressedFormat;
    }
public:
    enum VK_FORMAT_BC1_RGB_UNORM_BLOCK  = 131;
    enum VK_FORMAT_BC2_UNORM_BLOCK      = 135;
    enum VK_FORMAT_BC3_UNORM_BLOCK      = 137;

    uint compressedFormat;  // VkFormat

    static DDS read(string filename) {
        auto r = new FileByteReader(filename);

        auto magic = r.read!uint;
        if(magic!=0x20534444) {
            bail("Not a valid DDS file");
        }

        auto header = readHeader(r);
        chat("header = %s", header);

        r.rewind();
        r.skip(4+124);

        switch(header.format.fourCC) {
            case FOURCC.DXT1 :
                return compressed(header, 8, r, VK_FORMAT_BC1_RGB_UNORM_BLOCK);
            case FOURCC.DXT3 :
                log("WARN: Prefer DXT5 over DXT3 for RGBA images");
                return compressed(header, 16, r, VK_FORMAT_BC2_UNORM_BLOCK);
            case FOURCC.DXT5 :
                return compressed(header, 16, r, VK_FORMAT_BC3_UNORM_BLOCK);
            default :
                bail("Format not supported: %s".format(header.format));
                break;
        }

        return null;
    }
private:
    static void bail(string msg) {
        throw new Error(msg);
    }
    static Header readHeader(ByteReader r) {
        Header h = {
            size         : r.read!uint,
            flags        : r.read!uint.as!DDSD,
            height       : r.read!uint,
            width        : r.read!uint,
            pitch        : r.read!uint,
            depth        : r.read!uint,
            mipMapLevels : r.read!uint,
            format       : readPixelFormat(r.skip(11*4)),
            caps         : r.read!uint.as!DDSCAPS,
            caps2        : r.read!uint.as!DDSCAPS2
        };
        r.skip(3*4);
        if(h.size!=124) bail("DDSHeader.size should be 124");
        return h;
    }
    static DDSPixelFormat readPixelFormat(ByteReader r) {
        DDSPixelFormat f = {
            size        : r.read!uint,
            flags       : r.read!uint.as!DDPF,
            fourCC      : r.read!uint.as!FOURCC,
            RGBBitCount : r.read!uint,
            RBitMask    : r.read!uint,
            GBitMask    : r.read!uint,
            BBitMask    : r.read!uint,
            ABitMask    : r.read!uint
        };
        if(f.size!=32) bail("DDSPixelFormat.size should be 32");
        if((f.flags & DDPF.FOURCC)==0) bail("Expecting a fourcc");
        if((f.flags & DDPF.ALPHAPIXELS) != 0) bail("Unsupported ALPHAPIXELS");
        if(f.fourCC == FOURCC.DX10) bail("FOURCC.DX10 not supported");
        return f;
    }
    static DDS compressed(Header header, uint blockBytes, ByteReader r, uint compressedFormat) {

        auto width          = header.width;
        auto height         = header.height;
        auto bitsPerPixel   = 1;
        ubyte[] data;

        auto size = maxOf(4, width)/4 * maxOf(4, height)/4 * blockBytes;

        auto mipMapCount = header.flags.isSet(DDSD.MIPMAPCOUNT) ? header.mipMapLevels : 1;

        if(mipMapCount==1) {
            /** Everything */

            if(r.remaining()!=size) bail("Expecting %s bytes".format(size));

            data = r.readArray!ubyte(r.remaining());

            return new DDS(width, height, bitsPerPixel, data, compressedFormat);

        } else bail("Mip maps - implement me");
        assert(false);
    }
}

private:

struct Header {
    uint size;          // always 124
    DDSD flags;
    uint height;
    uint width;
    uint pitch;
    uint depth;
    uint mipMapLevels;
    // reserved 11 ints
    DDSPixelFormat format;
    DDSCAPS caps;
    DDSCAPS2 caps2;
    //uint caps3 = 0;
    //uint caps4 = 0;
    //uint reserved;

    string toString() {
        return "Header(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)".format(
            size, flags, height, width, pitch, depth, mipMapLevels, format, toArray!DDSCAPS(caps), toArray!DDSCAPS2(caps2)
        );
    }
}
struct DDS_HEADER_DXT10 {
    DXGI_FORMAT  dxgiFormat;
    D3D10_RESOURCE_DIMENSION resourceDimension;
    uint miscFlag;      // 0x4 = a 2D texture is a cube-map texture
    uint arraySize;
    uint miscFlags2;    // alpha mode is in (miscFlags2 & 3) the rest is reserved

    string toString() {
        return "DDS_HEADER_DXT10(%s,%s,%s,%s,%s)".format(dxgiFormat, resourceDimension, miscFlag, arraySize, miscFlags2);
    }
}
struct DDSPixelFormat {
    uint size;          // Always 32
    DDPF flags;
    FOURCC fourCC;
    uint RGBBitCount;
    uint RBitMask;
    uint GBitMask;
    uint BBitMask;
    uint ABitMask;

    string toString() {
        return "DDSPixelFormat(%s,%s,%s,%s,%s,%s,%s,%s)".format(size, toArray!DDPF(flags), fourCC, RGBBitCount, RBitMask, GBitMask, BBitMask, ABitMask);
    }
}
enum DDS_ALPHA_MODE : uint {
    UNKNOWN 	  = 0x0,  // Alpha channel content is unknown. This is the value for legacy files, which typically is assumed to be 'straight' alpha. 	0x0
    STRAIGHT 	  = 0x1,  // Any alpha channel content is presumed to use straight alpha. 	0x1
    PREMULTIPLIED = 0x2,  // Any alpha channel content is using premultiplied alpha. The only legacy file formats that indicate this information are 'DX2' and 'DX4'. 	0x2
    OPAQUE 	      = 0x3,  // Any alpha channel content is all set to fully opaque. 	0x3
    CUSTOM 	      = 0x4   // Any alpha channel content is being used as a 4th channel and is not intended to represent transparency (straight or premultiplied).
}
enum DDPF : uint {
    ALPHAPIXELS = 0x1,      // Texture contains alpha data; ABitMask contains valid data.
    ALPHA       = 0x2,
    FOURCC      = 0x4,      // Texture contains compressed RGB data; dwFourCC contains valid data.
    RGB         = 0x40,
    YUV         = 0x200,
    LUMINANCE   = 0x20000
}
enum FOURCC : uint {
    DXT1 = 0x31545844, // 0x44=D
    DXT2 = 0x32545844,
    DXT3 = 0x33545844,
    DXT4 = 0x34545844,
    DXT5 = 0x35545844,
    DX10 = 0x30315844
}
enum DDSD : uint {
    CAPS        = 0x1,
    HEIGHT      = 0x2,
    WIDTH       = 0x4,
    PITCH       = 0x8,
    PIXELFORMAT = 0x1000,
    MIPMAPCOUNT = 0x20000,
    LINEARSIZE  = 0x80000,
    DEPTH       = 0x800000
}
enum D3D10_RESOURCE_DIMENSION : uint {
  UNKNOWN,
  BUFFER,
  TEXTURE1D,
  TEXTURE2D,
  TEXTURE3D
}
enum DDSCAPS : uint {
    COMPLEX     = 0x8,
    TEXTURE     = 0x1000,
    MIPMAP      = 0x400000
}
enum DDSCAPS2 : uint {
    CUBEMAP             = 0x200, 	// Required for a cube map.
    CUBEMAP_POSITIVEX 	= 0x400,    // Required when these surfaces are stored in a cube map.
    CUBEMAP_NEGATIVEX 	= 0x800,    // Required when these surfaces are stored in a cube map.
    CUBEMAP_POSITIVEY 	= 0x1000,   // Required when these surfaces are stored in a cube map.
    CUBEMAP_NEGATIVEY 	= 0x2000,   // Required when these surfaces are stored in a cube map.
    CUBEMAP_POSITIVEZ 	= 0x4000,   // Required when these surfaces are stored in a cube map.
    CUBEMAP_NEGATIVEZ 	= 0x8000,   // Required when these surfaces are stored in a cube map.
    VOLUME 	            = 0x200000  // Required for a volume texture.
}
enum DXGI_FORMAT : uint {
    UNKNOWN,
    R32G32B32A32_TYPELESS,
    R32G32B32A32_FLOAT,
    R32G32B32A32_UINT,
    R32G32B32A32_SINT,
    R32G32B32_TYPELESS,
    R32G32B32_FLOAT,
    R32G32B32_UINT,
    R32G32B32_SINT,
    R16G16B16A16_TYPELESS,
    R16G16B16A16_FLOAT,
    R16G16B16A16_UNORM,
    R16G16B16A16_UINT,
    R16G16B16A16_SNORM,
    R16G16B16A16_SINT,
    R32G32_TYPELESS,
    R32G32_FLOAT,
    R32G32_UINT,
    R32G32_SINT,
    R32G8X24_TYPELESS,
    D32_FLOAT_S8X24_UINT,
    R32_FLOAT_X8X24_TYPELESS,
    X32_TYPELESS_G8X24_UINT,
    R10G10B10A2_TYPELESS,
    R10G10B10A2_UNORM,
    R10G10B10A2_UINT,
    R11G11B10_FLOAT,
    R8G8B8A8_TYPELESS,
    R8G8B8A8_UNORM,
    R8G8B8A8_UNORM_SRGB,
    R8G8B8A8_UINT,
    R8G8B8A8_SNORM,
    R8G8B8A8_SINT,
    R16G16_TYPELESS,
    R16G16_FLOAT,
    R16G16_UNORM,
    R16G16_UINT,
    R16G16_SNORM,
    R16G16_SINT,
    R32_TYPELESS,
    D32_FLOAT,
    R32_FLOAT,
    R32_UINT,
    R32_SINT,
    R24G8_TYPELESS,
    D24_UNORM_S8_UINT,
    R24_UNORM_X8_TYPELESS,
    X24_TYPELESS_G8_UINT,
    R8G8_TYPELESS,
    R8G8_UNORM,
    R8G8_UINT,
    R8G8_SNORM,
    R8G8_SINT,
    R16_TYPELESS,
    R16_FLOAT,
    D16_UNORM,
    R16_UNORM,
    R16_UINT,
    R16_SNORM,
    R16_SINT,
    R8_TYPELESS,
    R8_UNORM,
    R8_UINT,
    R8_SNORM,
    R8_SINT,
    A8_UNORM,
    R1_UNORM,
    R9G9B9E5_SHAREDEXP,
    R8G8_B8G8_UNORM,
    G8R8_G8B8_UNORM,
    BC1_TYPELESS,
    BC1_UNORM,
    BC1_UNORM_SRGB,
    BC2_TYPELESS,
    BC2_UNORM,
    BC2_UNORM_SRGB,
    BC3_TYPELESS,
    BC3_UNORM,
    BC3_UNORM_SRGB,
    BC4_TYPELESS,
    BC4_UNORM,
    BC4_SNORM,
    BC5_TYPELESS,
    BC5_UNORM,
    BC5_SNORM,
    B5G6R5_UNORM,
    B5G5R5A1_UNORM,
    B8G8R8A8_UNORM,
    B8G8R8X8_UNORM,
    R10G10B10_XR_BIAS_A2_UNORM,
    B8G8R8A8_TYPELESS,
    B8G8R8A8_UNORM_SRGB,
    B8G8R8X8_TYPELESS,
    B8G8R8X8_UNORM_SRGB,
    BC6H_TYPELESS,
    BC6H_UF16,
    BC6H_SF16,
    BC7_TYPELESS,
    BC7_UNORM,
    BC7_UNORM_SRGB,
    AYUV,
    Y410,
    Y416,
    NV12,
    P010,
    P016,
    _420_OPAQUE,
    YUY2,
    Y210,
    Y216,
    NV11,
    AI44,
    IA44,
    P8,
    A8P8,
    B4G4R4A4_UNORM,
    P208,
    V208,
    V408,
    SAMPLER_FEEDBACK_MIN_MIP_OPAQUE,
    SAMPLER_FEEDBACK_MIP_REGION_USED_OPAQUE,
    FORCE_UINT
}
