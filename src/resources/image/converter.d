module resources.image.converter;

import resources.all;

final class ImageConverter {

    static R16 toR16(T)(T img, bool normalised=false)
        if(is(T==BMP) || is(T==PNG))
    {
        auto r16 = new R16(img.width, img.height);
        r16.bytesPerPixel = 2;
        r16.data.length = img.width*img.height*2;

        auto dest = cast(HalfFloat*)r16.data.ptr;
        auto src  = img.data.ptr;
        foreach(i; 0..img.width*img.height) {
            float red = src[0];
            if(normalised) {
                red = red/255.0f;
            }
            *dest = HalfFloat(red);

            src+=img.bytesPerPixel;
            dest++;
        }

        return r16;
    }
    static R32 toR32(T)(T img, bool normalised=false)
        if(is(T==BMP) || is(T==PNG))
    {
        auto r32 = new R32(img.width, img.height);
        r32.bytesPerPixel = 4;
        r32.data.length = img.width*img.height*4;

        auto dest = cast(float*)r32.data.ptr;
        auto src  = img.data.ptr;
        foreach(i; 0..img.width*img.height) {
            float red = src[0];
            if(normalised) {
                red = red/255.0f;
            }
            *dest = red;

            src+=img.bytesPerPixel;
            dest++;
        }

        return r32;
    }
}

