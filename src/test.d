

import std.stdio    : writefln;
import std.file     : read;
import std.datetime.stopwatch : StopWatch;
import resources;
import std.random   : uniform01;
import maths;

void main() {
    writefln("Testing resources");

    //testPDC();

    //testDeflate();
    testZip();

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
//    testPNG();
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
    auto pdc = new PDC("testdata/geo");

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

    writefln("Num entries = %s", zip.getNumEntries);
    writefln("Comment     = %s", zip.getComment);
    writefln("Filenames   = %s", zip.getFilenames);

    auto file1 = zip.get("file1.txt");
    writefln("file1=%s", file1);
    writefln("\tfilename          = %s", file1.filename);
    writefln("\tuncompressed size = %s", file1.uncompressedSize);
    writefln("\tcompressed size   = %s", file1.compressedSize);
    writefln("\tis decompressed   = %s", file1.isDecompressed);
    writefln("\tdata              = %s", cast(string)file1.getUncompressed());
    writefln("\tis decompressed   = %s", file1.isDecompressed);

    auto file2 = zip.get("file2.txt");
    writefln("file2=%s", file2);
    writefln("\tfilename          = %s", file2.filename);
    writefln("\tuncompressed size = %s", file2.uncompressedSize);
    writefln("\tcompressed size   = %s", file2.compressedSize);
    writefln("\tis decompressed   = %s", file2.isDecompressed);
    writefln("\tdata              = %s", cast(string)file2.getUncompressed());
    writefln("\tis decompressed   = %s", file2.isDecompressed);

    auto bib = zip.get("bib");
    writefln("bib=%s", bib);
    writefln("\tfilename          = %s", bib.filename);
    writefln("\tuncompressed size = %s", bib.uncompressedSize);
    writefln("\tcompressed size   = %s", bib.compressedSize);
    writefln("\tis decompressed   = %s", bib.isDecompressed);
    writefln("\tdata              = %s", bib.getUncompressed().length);
    writefln("\tis decompressed   = %s", bib.isDecompressed);

    // import common;
    // auto f = new FileByteWriter("tempbib.txt");
    // f.writeArray!ubyte(bib.getUncompressed());
    // f.close();

    zip.close();
}
