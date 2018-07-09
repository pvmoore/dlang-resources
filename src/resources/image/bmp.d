module resources.image.bmp;
/**
 *  Handle the Windows .BMP image file format.
 *
 *  Only BGR888 and ABGR8888 formats can be loaded.
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

final class BMP : Image {

    PNG getPNG() {
        auto b = new PNG;
        b.width = width;
        b.height = height;
        b.bytesPerPixel = bytesPerPixel;
        b.data = data.dup;
        return b;
    }

    static auto create_RGBA8888(uint w, uint h) {
        auto bmp          = new BMP();
        bmp.width         = w;
        bmp.height        = h;
        bmp.bytesPerPixel = 4;
        bmp.data.length   = w*h*4;
        return bmp;
	}
	static auto create_RGB888(uint w, uint h) {
        auto bmp          = new BMP();
        bmp.width         = w;
        bmp.height        = h;
        bmp.bytesPerPixel = 3;
        bmp.data.length   = w*h*3;
        return bmp;
	}
	static auto create_RGB888(uint w, uint h, ubyte[] data) {
        auto bmp          = new BMP();
        bmp.width         = w;
        bmp.height        = h;
        bmp.bytesPerPixel = 3;
        bmp.data          = data;
        return bmp;
    }
    static auto create_RGB8(uint w, uint h, ubyte[] data) {
        auto bmp          = new BMP();
        bmp.width         = w;
        bmp.height        = h;
        bmp.bytesPerPixel = 3;
        bmp.data.length   = w*h*3;
        // convert to RGB888
        ulong dest = 0;
        for(auto i=0; i<data.length; i++) {
            bmp.data[dest+0] = data[i];
            bmp.data[dest+1] = data[i];
            bmp.data[dest+2] = data[i];
            dest+=3;
        }
        return bmp;
    }
    // assumes BGR_888 or ABGR_8888 format
    static auto read(string filename) {
        auto bmp   = new BMP();
    	scope file = File(filename, "rb");

    	HEADER[1] headerArray;
    	DIBHEADER[1] dibArray;
    	file.rawRead(headerArray);
    	file.rawRead(dibArray);

    	HEADER header = headerArray[0];
    	DIBHEADER dib = dibArray[0];

        if(header.dataOffset > HEADER.sizeof + DIBHEADER.sizeof) {
            // skip some stuff before the actual pixel data starts
    	    file.seek(header.dataOffset);
    	}

    	if(dib.bitsPerPixel!=24 && dib.bitsPerPixel!=32) {
    	    throw new Error("Unsupported BMP: '%s'".format(filename));
    	}

        // If dib.height > 0 then pixel data is in bottom-left to top-right order.
        // If dib.height < 0 then pixel data is in top-left to bottom-right order.
        // We want it in top-left to bottom-right layout.
    	bmp.width	      = dib.width;
    	bmp.height        = abs(dib.height);
    	bmp.bytesPerPixel = dib.bitsPerPixel/8;

        bool invertY      = dib.height > 0;
    	int padding		  = (bmp.width*bmp.bytesPerPixel) & 3;
    	int widthBytes	  = bmp.width*bmp.bytesPerPixel + padding;
    	ubyte[] line	  = new ubyte[widthBytes];

    	//writefln("bpp=%s width=%s height=%s padding=%s widthBytes=%s", bmp.bytesPerPixel, bmp.width, dib.height, padding, widthBytes);

        //auto buf = appender!(ubyte[]);
        bmp.data.length = bmp.width*bmp.height*bmp.bytesPerPixel;
        int width       = bmp.width*bmp.bytesPerPixel;
        long dest       = invertY ? (bmp.height-1)*width : 0;

    	for(auto y=0; y<bmp.height; y++) {
    		file.rawRead(line);

            for(auto x=0;x<bmp.width;x++) {
                if(bmp.bytesPerPixel==3) {
                    // swap bgr to rgb
                    long i = x*3;
                    ubyte temp = line[i];
                    line[i]    = line[i+2];
                    line[i+2]  = temp;
                } else {
                    // swap abgr to rgba
                    long i = x*bmp.bytesPerPixel;

                    ubyte a = line[i];
                    ubyte b = line[i+1];
                    ubyte g = line[i+2];
                    ubyte r = line[i+3];

                    line[i+0] = r;
                    line[i+1] = g;
                    line[i+2] = b;
                    line[i+3] = a;
                }
            }
    		//buf.put(line);
    		bmp.data[dest..dest+width] = line[0..width];
    		dest += invertY ? -width : width;
    	}
    	//bmp.data = buf.data;
    	return bmp;
    }

    void set(uint x, uint y, uvec4 value) {
        uint i = (x + (y*width)) * bytesPerPixel;
        data[i+0] = cast(ubyte)(value.r&0xff);
        data[i+1] = cast(ubyte)(value.g&0xff);
        data[i+2] = cast(ubyte)(value.b&0xff);
        if(bytesPerPixel>3) {
            data[i+3] = cast(ubyte)(value.a&0xff);
        }
    }
    uvec4 get(uint x, uint y) {
        uint i = (x + (y*width))*bytesPerPixel;
        return uvec4(
            data[i],
            data[i+1],
            data[i+2],
            bytesPerPixel==4 ? data[i+3] : 0
        );
    }

    // writes as BGR888 or BGRA8888 format with the height inverted.
    void write(string filename) {
        HEADER header;
        DIBHEADER dib;

        dib.width        = width;
        dib.height       = -height; // top-left -> bottom-right layout
        dib.bitsPerPixel = cast(ushort)(bytesPerPixel*8);

        auto file = File(filename, "wb");

        // data needs to be written in BGR format
        // with lines padded to 4 byte boundary
        int padding    = (width*bytesPerPixel) & 3;
        int widthBytes = width*bytesPerPixel + padding;
        ubyte[] line   = new ubyte[widthBytes];

        // write the headers
        file.rawWrite([header]);
        file.rawWrite([dib]);

        // write the lines
        long src = 0;
        for(auto y=0; y<height; y++) {
            long dest = 0;
            for(auto x=0; x<width; x++) {
                if(bytesPerPixel==4) {
                    // swap rgba to bgra
                    line[dest+0] = data[src+2]; // b
                    line[dest+1] = data[src+1]; // g
                    line[dest+2] = data[src+0]; // r
                    line[dest+3] = data[src+3]; // a
                } else {
                    // swap rgb to bgr
                    line[dest+0] = data[src+2]; // b
                    line[dest+1] = data[src+1]; // g
                    line[dest+2] = data[src+0]; // r
                }
                src  += bytesPerPixel;
                dest += bytesPerPixel;
            }
            file.rawWrite(line);
        }
        file.close();
    }
}

private:

align(1) struct HEADER {
align(1):
	ubyte magic1 = 'B', magic2 = 'M';
	uint fileSize = 0;
	short reserved1;
	short reserved2;
	uint dataOffset = HEADER.sizeof + DIBHEADER.sizeof;
}
static assert(HEADER.sizeof==14);

struct DIBHEADER {
	uint size = DIBHEADER.sizeof;
	int width;
	int height;
	ushort planes = 1;
	ushort bitsPerPixel = 24;
	uint compression = 0;	// no compression
	uint imageSize = 0;		// o for uncompressed bitmaps
	int horizRes = 2835;
	int vertRes = 2835;
	uint numColours = 0;
	uint numImportantColours = 0;
}
static assert(DIBHEADER.sizeof==40);
