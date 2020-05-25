
import resources;
import maths;
import common : BitWriter, BitReader, ByteReader, From;

import std.stdio    : writefln;
import std.file     : read;
import std.random   : uniform01;
import std.array    : appender;
import std.format   : format;
import std.range    : array;
import std.datetime.stopwatch  : StopWatch;
import std.algorithm.searching : minElement, maxElement;
import std.algorithm.iteration : each, map, sum;

void main() {
    writefln("Testing resources");

    testDDS();

    //testPDC();
    //testPDC2();

    //testDeflate();
    //testZip();

    //test7Zip();
    //testLZMA();

    //testEntropyCoders();

    //testPDB();
    //testPE();
    //testCOFF();

    //
    //writefln("%s", r32.get(0,0));
    //writefln("%s", r32.get(511,511));
    //
    //r32 = R32.read("C:/pvmoore/_assets/images/heightmaps/heightmap.r32");
    //
    //writefln("%s", r32.get(0,0));
    //writefln("%s", r32.get(511,511));

    //testImageConverter();
//    testBMP();
    //testPNG();
//    testPerlin();
//    testLZ4();
    //testHGT();
}
void testPerlin() {
    /*import std.math : sin,cos,fmod;
    import std.random : uniform;
    auto noise = new ImprovedNoise();

    auto bmp = BMP.create_RGB888(256,256);
    for(auto y=0; y<256; y++)
    for(auto x=0; x<256; x++) {
        float xx = 10.0*(x/256.0);
        float yy = 10.0*(y/256.0);
        float v = 0.5 + noise.get(xx,yy,0,4,0.5);
        v = clamp(v,0f,1f);
        ulong i = (x+y*256)*3;
        bmp.data[i+0] = cast(ubyte)(v*255);
        bmp.data[i+1] = cast(ubyte)(v*255);
        bmp.data[i+2] = cast(ubyte)(v*255);
    }
    bmp.write("perlin2.bmp");
*/

    /*auto noise = new PerlinNoise2D(256,256);
    noise//.setSeed(1)
         .setOctaves(7)
         .setPersistence(0.7)
         .generate();
    auto perlin  = noise.get();

    auto bmp = BMP.create_RGB888(256,256);
    for(auto i=0; i<perlin.length; i++) {
        bmp.data[i*3+0] = cast(ubyte)(perlin[i]*256);
        bmp.data[i*3+1] = cast(ubyte)(perlin[i]*256);
        bmp.data[i*3+2] = cast(ubyte)(perlin[i]*256);
    }
    bmp.write("perlin_7.bmp");*/
}
void testImageConverter() {
    auto bmp = BMP.create_RGBA8888(8,8);
    bmp.set(0,0, uvec4(1,2,3,4));
    bmp.set(1,0, uvec4(90,8,7,6));
    bmp.set(1,1, uvec4(255,11,13,17));
    writefln("bmp[0,0]=%s", bmp.get(0,0));
    writefln("bmp[1,0]=%s", bmp.get(1,0));
    writefln("bmp[1,1]=%s", bmp.get(1,1));

    auto r16 = ImageConverter.toR16(bmp);
    writefln("r16[0,0]=%.1f", r16.get(0,0));
    writefln("r16[1,0]=%.1f", r16.get(1,0));
    writefln("r16[1,1]=%.1f", r16.get(1,1));

    auto r32 = ImageConverter.toR32(bmp);
    writefln("r32[0,0]=%.1f", r32.get(0,0));
    writefln("r32[1,0]=%.1f", r32.get(1,0));
    writefln("r32[1,1]=%.1f", r32.get(1,1));

    auto r32n = ImageConverter.toR32(bmp, true);
    writefln("r32[0,0]=%.3f", r32n.get(0,0));
    writefln("r32[1,0]=%.3f", r32n.get(1,0));
    writefln("r32[1,1]=%.3f", r32n.get(1,1));
}
void testBMP() {
//    auto bmp = BMP.create_RGB888(16,16);
//    bmp.data[0] = 255;
//    bmp.data[1] = 0;
//    bmp.data[2] = 0;
//
//    bmp.data[255*3+0] = 255;
//    bmp.data[255*3+1] = 255;
//    bmp.data[255*3+2] = 255;
//    bmp.write("here.bmp");

    //auto abgr = BMP.read("/pvmoore/_assets/images/bmp/goddess_abgr.bmp");
    //abgr.write("goddess.bmp");
}
void testPNG() {

    auto rock3 = PNG.read("/pvmoore/_assets/images/png/rock3.png");

    auto png = PNG.read("/pvmoore/_assets/images/png/tile.png");

    //auto png = PNG.read("/pvmoore/d/libs/opengl3/images/skybox2/front.png");


    assert(png.width==128);
    assert(png.height==128);
    assert(png.bytesPerPixel==4);
    assert(png.data.length==128*128*4);

    auto bmp = png.getBMP();
    bmp.write("tile.bmp");

    auto alpha = png.getAlpha();
    assert(alpha.width==128 && alpha.height==128 &&
           alpha.bytesPerPixel==1 && alpha.data.length==128*128);
}
void testDDS() {
    writefln("Testing DDS");

    auto rock3 = DDS.read("/pvmoore/_assets/images/dds/brick.dds");
}
void testLZ4() {
    ubyte[] test1 = cast(ubyte[])read("testdata/test1.txt");
    ubyte[] test2 = cast(ubyte[])read("testdata/test2.txt");
    ubyte[] bib = cast(ubyte[])read("testdata/bib");

    StopWatch w; w.start();
    ubyte[] d1 = LZ4.decompress("testdata/test1.lz4");
    assert(d1.length==test1.length);
    assert(d1[]==test1[]);

    ubyte[] d2 = LZ4.decompress("testdata/test2.lz4");
    assert(d2.length==test2.length);
    assert(d2[]==test2[]);

    ubyte[] d3 = LZ4.decompress("testdata/bib.lz4");
    assert(d3.length==bib.length);
    assert(d3[]==bib[]);

    ubyte[] d4 = LZ4.decompress("testdata/bib2.lz4");
    assert(d4.length==bib.length);
    assert(d4[]==bib[]);
    w.stop();
    writefln("Took %s millis", w.peek().total!"nsecs"/1_000_000.0);

    // 470 480 ms
}
void testHGT() {
    auto hgt = HGT.read("/temp/heightmaps/N47E006.hgt");
}
void testPDC() {
    writefln("#######################################");
    writefln("Testing PDC");
    writefln("#######################################");
    auto pdc = new PDC("testdata/geo");

}
void testPDC2() {
    writefln("#######################################");
    writefln("Testing PDC2");
    writefln("#######################################");
    auto pdc2 = new PDC2("testdata/bib");
    auto bytes = pdc2.encode();




}
void testDeflate() {
    writefln("#######################################");
    writefln("Testing Deflate");
    writefln("#######################################");

}
void testZip() {
    writefln("#######################################");
    writefln("Testing Zip");
    writefln("#######################################");

    auto zip = new Zip("testdata/example.zip");

    writefln("Num entries       = %s", zip.getNumEntries);
    writefln("Comment           = %s", zip.getComment);
    writefln("Filenames         = %s", zip.getFilenames);
    writefln("Compressed size   = %s", zip.getCompressedSize);
    writefln("Uncompressed size = %s", zip.getUncompressedSize);
    writefln("");

    foreach(name; zip.getFilenames) {
        auto e = zip.get(name);

        writefln("%s", e);
        writefln("\tfilename              = %s", e.filename);
        writefln("\tuncompressed size     = %s", e.uncompressedSize);
        writefln("\tcompressed size       = %s", e.compressedSize);
        writefln("\thas been decompressed = %s", e.hasBeenDecompressed);
        writefln("\tdata                  = %s", e.getUncompressed().length);
    }

    // import common;
    // auto f = new FileByteWriter("tempbib.txt");
    // f.writeArray!ubyte(bib.getUncompressed());
    // f.close();

    zip.close();
}
void test7Zip() {
    writefln("#######################################");
    writefln("Testing 7Zip");
    writefln("#######################################");

    auto _7z = new _7ZipDecompressor("testdata/bib.7z");
    _7z.decompress();

}
void testLZMA() {
    writefln("#######################################");
    writefln("Testing LZMA");
    writefln("#######################################");


}
void testEntropyCoders() {
    writefln("Testing Huffman...");

    ubyte[] bib = cast(ubyte[])read("testdata/bib");
    writefln("bib length = %s", bib.length);

    uint[256] frequencies;
    foreach(b; bib) {
        frequencies[b]++;
    }

    /**
     *  Return the number of bits required to store
     *  _value_ given a total set of size _total_.
     *  eg. entropy(1, 256) == 8 (bits)
     *      entropy(1, 3)   == 1.58496 (bits)
     */
    // double entropyBits(double value, double total) {
    //     import std.math : log2;
    //     return log2(total/value);
    // }

    void testHuffmanCoder() {
        auto tree = new HuffmanCoder().createFromFrequencies(frequencies);
        //writefln("%s", tree);
        writefln("bit lengths = %s -> %s", tree.getShortestBitLength, tree.getLongestBitLength);

        // todo - Encode bib using tree and record length.
        //        Time the operation
        ulong numBits;
        auto outStream = appender!(ubyte[]);
        auto w = new BitWriter((it) {numBits+=8; outStream~= it; });
        foreach(b; bib) {
            tree.encode(w, b);
        }
        w.flush();

        // 582088 bits (72761 bytes)
        writefln("Huffman entropy = %s bits (%s bytes)", numBits, numBits/8);

        // check the encoded stream
        auto br = new ByteReader(outStream.data);
        auto r  = new BitReader(() { return br.read!ubyte; });
        foreach(i; 0..bib.length) {
            int value = tree.decode(r);
            assert(bib[i] == cast(ubyte)value);
        }
        writefln("Huffman decode succeeded");

    }
    void testArithmeticCoder() {
        ulong[] freqL = frequencies.array.map!(it=>cast(ulong)it).array;
        auto model    = new StaticOrder0Model(freqL);
        auto ac       = new ArithmeticCoder(model);

        ulong numBits;
        auto outStream = appender!(ubyte[]);
        auto w = new BitWriter((it) {numBits+=8; outStream~= it; });

        ac.beginEncoding();
        foreach(b; bib) {
            ac.encode(w, b);
        }
        ac.endEncoding(w);
        writefln("ArithmeticCoder entropy = %s bits (%s bytes)", numBits, numBits/8);

        // check the encoded stream
        auto br = new ByteReader(outStream.data);
        auto r  = new BitReader(() { return br.read!ubyte; });
        ac.beginDecoding(r);
        foreach(i; 0..bib.length) {
            int value = ac.decode(r);
            assert(bib[i] == cast(ubyte)value, "i=%s".format(i));
        }
        ac.endDecoding();
        writefln("ArithmeticCoder decode succeeded");
    }
    void testRangeCoder() {

    }
    void testPennyDropCoder() {

    }

    // 578632 bits (72329.1 bytes)
    auto optimalEntropy = bib.map!(it=>entropyBits(frequencies[it], bib.length)).sum();

    // foreach(i, freq; frequencies) {
    //     writefln("[%s] %s", i, freq);
    // }

    writefln("Lowest freq  = %s", bib.minElement);
    writefln("Largest freq = %s", bib.maxElement);
    writefln("Optimal entropy = %s bits (%s bytes)", optimalEntropy, optimalEntropy/8);

    testHuffmanCoder();
    testArithmeticCoder();
    testRangeCoder();
    testPennyDropCoder();
}
void testPDB() {
    writefln("#######################################");
    writefln("Testing PDB");
    writefln("#######################################");

    auto pdb = new PDB("testdata/test.pdb");
    //auto pdb = new PDB("testdata/core.pdb");
    pdb.read();
}
void testCOFF() {
    writefln("#######################################");
    writefln("Testing COFF");
    writefln("#######################################");

    import common : FileByteReader;
    auto coff = new COFF("testdata/statics.obj");
    coff.readHeader();
    coff.readSections();
    auto code = coff.getCode();
    writefln("code = %s bytes", code.length);
}
void testPE() {
    writefln("#######################################");
    writefln("Testing PE");
    writefln("#######################################");

    //auto pe = new PE("C:/pvmoore/cpp/Core/x64/Debug/Test.exe");
    auto pe = new PE("C:/pvmoore/cpp/Core/x64/Release/Test.exe");
    //auto pe = new PE("bin-test.exe");
    pe.read();

    auto codeSections = pe.getCodeSectionsInOrder();
    writefln("Found %s code sections:", codeSections.length);
    foreach(ref s; codeSections) {
        writefln("    %s", s);
    }
    writefln("Entry point = %s", pe.getEntryPoint());

    auto code = pe.getCode();
    writefln("code = %s", code.length);
}