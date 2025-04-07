module test;

import resources;
import maths : uvec4;

import std.stdio : writefln;

import test_data;
import test_json5;

void main() {
    writefln("Testing resources");

    //testSpirv();

    //testData();
    //testJson5();


    //testObj();
    testDLL();

    //testDDS();

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
//    testPNG();
//    testPerlin();
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
    writefln("Testing PNG");

    // Read
    writefln("Reading logo.png");
    auto logo = PNG.read("testdata/logo.png");
    writefln("logo = %s", logo);
    
    assert(logo.width==128);
    assert(logo.height==128);
    assert(logo.bytesPerPixel==4);
    assert(logo.data.length==128*128*4);

    auto alpha = logo.getAlpha();
    assert(alpha.width==128 && alpha.height==128 &&
           alpha.bytesPerPixel==1 && alpha.data.length==128*128);

    // write
    writefln("Writing png to logo1.png ...");
    logo.write("testdata/logo1.png");

    auto logo1 = PNG.read("testdata/logo1.png");

    writefln("Checking data");
    foreach(i; 0..logo.data.length) {
        assert(logo.data[i] == logo1.data[i]);
    }
    writefln("OK");   
}
void testDDS() {
    writefln("Testing DDS");

    writefln("Reading brick.dds (BC1)");
    auto brick = DDS.read("testdata/brick.dds");
    writefln("brick = %s", brick);

    writefln("Reading logo.dds (BC7)");
    auto logo = DDS.read("testdata/logo-bc7.dds");
    writefln("logo = %s", logo);

}
void testHGT() {
    auto hgt = HGT.read("/temp/heightmaps/N47E006.hgt");
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

    import common.io : FileByteReader;
    auto coff = new COFF("testdata/statics.obj");
    coff.readHeader();
    coff.readSections();
    auto code = coff.getCode();
    writefln("code = %s bytes", code.length);
}
void testDLL() {
    writefln("#######################################");
    writefln("Testing DLL");
    writefln("#######################################");

    //auto pe = new PE("C:/pvmoore/cpp/Core/x64/Debug/Test.exe");
    auto dll = new PE("C:/pvmoore/_dlls/glfw3.3.7.dll");
    //auto pe = new PE("bin-test.exe");
    dll.read();

    auto codeSections = dll.getCodeSectionsInOrder();
    writefln("Found %s code sections:", codeSections.length);
    foreach(ref s; codeSections) {
        writefln("    %s", s);
    }
    writefln("Entry point = %s", dll.getEntryPoint());

    auto code = dll.getCode();
    writefln("code = %s", code.length);
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
void testObj() {
    writefln("#######################################");
    writefln("Testing Obj");
    writefln("#######################################");

    auto obj = Obj.read("testdata/suzanne.obj.txt");
}
void testSpirv() {
    writefln("#######################################");
    writefln("Testing SPIRV");
    writefln("#######################################");

    //auto spirv = SPIRV.read("C:/pvmoore/d/libs/vulkan/resources/shaders/vulkan/quad/Quad.spv");
    //auto spirv = SPIRV.read("C:\\pvmoore\\d\\apps\\blockie\\resources\\shaders\\pass1_marchM2_comp.spv");
    
    auto spirv = SPIRV.read("C:\\pvmoore\\d\\apps\\emerald\\resources\\shaders\\pathtracer_comp.spv");
    
    
    writefln("spirv = %s", spirv);
}
