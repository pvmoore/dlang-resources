module resources.image.webp.VP8L;

import resources.all;

/**
 * WebP lossless (VP8L)
 *
 * Examples:
 *   https://github.com/fencl/whale
 *   https://github.com/webmproject/libwebp
 *   https://chromium.googlesource.com/webm/libwebp/+/refs/tags/v1.6.0/src/dec/vp8l_dec.c
 *
 *  !! Partially implemented.
 */
final class VP8L {
public:
    enum PREDICTOR_TRANSFORM      = 0;
    enum COLOR_TRANSFORM          = 1;
    enum SUBTRACT_GREEN_TRANSFORM = 2;
    enum COLOR_INDEXING_TRANSFORM = 3;

    static struct argb {
        ubyte a, r, g, b;
    }

    uint width;
    uint height;

    void decode(BitReader bits) {
        this.width = bits.read(14) + 1;
        this.height = bits.read(14) + 1;
        bool alphaIsUsed = bits.read(1) != 0;
        uint versionNumber = bits.read(3);

        writefln("width = %s", width);
        writefln("height = %s", height);
        writefln("alphaIsUsed = %s", alphaIsUsed);
        writefln("versionNumber = %s", versionNumber);

        argb[] image = new argb[width*height];

        // Read the transforms
        while(bits.read(1) != 0) {
            auto transformType = bits.read(2);
            writefln("transformType = %s", transformType);
            switch(transformType) {
                case PREDICTOR_TRANSFORM: {
                    writefln("Predictor transform");
                    uint sizeBits = bits.read(3) + 2;
                    uint blockMask = (1 << sizeBits) - 1;
                    writefln("  sizeBits  = %s", sizeBits);
                    writefln("  blockMask = %s", blockMask);
                    uint transformWidth  = (width + blockMask) >> sizeBits;
                    uint transformHeight = (height + blockMask) >> sizeBits;
                    writefln("  transformWidth  = %s", transformWidth);
                    writefln("  transformHeight = %s", transformHeight);
                    break;
                }
                case COLOR_TRANSFORM: {
                    throwIf(true, "Color transform is not supported yet");
                    break;
                }
                case SUBTRACT_GREEN_TRANSFORM: {
                    writefln("Subtract green transform");
                    applySubtractGreenTransform(image);
                    break;
                }
                case COLOR_INDEXING_TRANSFORM: {
                    throwIf(true, "Color indexing transform is not supported yet");
                    break;
                }
                default: break; // we can't get here 
            }
        }

        argb[] colourCache;

        // Read the colour cache
        if(bits.read(1) != 0) {
            writefln("Colour cache is used");
            colourCache.length = 1 << bits.read(4);
            writefln("colorCacheSize = %s", colourCache.length);


        } else {
            writefln("Colour cache is not used");
        }


        uint[256] codeLengths;

        // Read the prefix codes
        bool isSimple = bits.read(1) != 0;
        writefln("isSimple = %s", isSimple);
        if(isSimple) {
            // Simple code length code
            uint numSymbols = bits.read(1) + 1;
            writefln("numSymbols = %s", numSymbols);

            bool isFirstSymbol8Bits = bits.read(1) != 0;
            writefln("isFirstSymbol8Bits = %s", isFirstSymbol8Bits);


            uint symbol0 = isFirstSymbol8Bits ? bits.read(8) : bits.read(1);
            writefln("symbol0 = %s", symbol0);
            codeLengths[symbol0] = 1;
            if(numSymbols == 2) {
                uint symbol1 = bits.read(8);
                writefln("symbol1 = %s", symbol1);
                codeLengths[symbol1] = 1;
            }

        } else {
            // Normal code length code
            uint numCodeLengths = bits.read(4) + 4;
            writefln("numCodeLengths = %s", numCodeLengths);

            uint[19] kCodeLengthCodeOrder = [
                17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
            ];
            uint[19] code_length_code_lengths;
            foreach(i; 0..numCodeLengths) {
                code_length_code_lengths[kCodeLengthCodeOrder[i]] = bits.read(3);
            }
            writefln("code_length_code_lengths = %s", code_length_code_lengths);

            uint bit2 = bits.read(1);
            writefln("bit2 = %s", bit2);

            uint colorCacheSize = 0; // where do we get this from?

            uint maxSymbolA = 256;
            uint maxSymbolR = 256;
            uint maxSymbolG = 256 +24 + colorCacheSize;
            uint maxSymbolB = 256;
            uint maxSymbolDistance = 40;

            if(bit2 == 1) {
                uint lengthNbits = 2 + 2 * bits.read(3);
                // maxSymbol = 2 + bits.read(lengthNbits);
                writefln("lengthNbits = %s", lengthNbits);
                // writefln("maxSymbol = %s", maxSymbol);
            }
        }
    }

private:
    void applySubtractGreenTransform(argb[] image) {
        foreach(i; 0..image.length) {
            auto g = image[i].g;
            image[i].r += g;
            image[i].b += g;
        }
    }
    void applyPredictorTransform(argb[] image, uint width, uint height) {
        // todo
    }
}
