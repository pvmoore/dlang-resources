module test_models;

import std.stdio : writefln;

import resources : Obj;
import resources.models.gltf;
import resources.models.voxels.magicavoxel.Vox;
import resources.models.voxels.Voxeliser;

import maths : Triangle, float3, float4, degrees;

void testModels() {
    //testVox();
    //testVoxelBlock();
    testVoxeliser();
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void testVox() {
    writefln("#######################################");
    writefln("Testing Vox");
    writefln("#######################################");

    string directory = "testdata/models/vox/";

    Vox vox = Vox.read(directory ~ "monu10.vox");
}
void testVoxelBlock() {
    writefln("#######################################");
    writefln("Testing VoxelBlock");
    writefln("#######################################");

    import resources.models.voxels.VoxelBlock;
    import maths : uint3;

    auto v = new VoxelBlock(uint3(256,256,256));
    
    //if(false) {
    debug {

    } else {
        import std.datetime.stopwatch : StopWatch, AutoStart;
        import std.random : uniform, uniform01;
        import common.utils : throwIf;

        uint count1, count2;

        foreach(z; 0..256) {
            foreach(y; 0..256) {
                foreach(x; 0..256) {
                    if(uniform01() < 0.5) {
                        v.set(uint3(x,y,z), cast(ubyte)(uniform01()*256));
                    }
                }
            }
        }

        const N = 1000000;
        uint3[] offsets = new uint3[N];
        uint[] sizes = new uint[N];
        foreach(i; 0..N) {
            sizes[i] = uniform(1,10);
            offsets[i] = uint3(uniform(0,256 - sizes[i]), uniform(0,256 - sizes[i]), uniform(0,256 - sizes[i]));
        }

        StopWatch watch1 = StopWatch(AutoStart.no);
        StopWatch watch2 = StopWatch(AutoStart.no);

        watch1.start();
        foreach(j; 0..10)
        foreach(i; 0..N) {
            uint3 offset = offsets[i];
            uint size = sizes[i];
            count1 += v.anySet(offset, size);
        }
        watch1.stop();
        watch2.start();
        foreach(j; 0..10)
        foreach(i; 0..N) {
            uint3 offset = offsets[i];
            uint size = sizes[i];
            count2 += v.anySet(offset, size);
        }
        watch2.stop();
        writefln("Time 1: %.2f ms", watch1.peek().total!"nsecs" / 1_000_000.0);
        writefln("Time 2: %.2f ms", watch2.peek().total!"nsecs" / 1_000_000.0);
        writefln("count1 = %s, count2 = %s", count1, count2);
        throwIf(count1 != count2, "Woops");
    }

    v.write("testdata/models/one.voxelblock");

    VoxelBlock v2 = VoxelBlock.read("testdata/models/one.voxelblock");
    assert(v.size == v2.size);
    assert(v.voxels[] == v2.voxels[]);
}
void testVoxeliser() {
    writefln("#######################################");
    writefln("Testing Voxeliser");
    writefln("#######################################");

    Voxeliser v = new Voxeliser;

    // v.addFace(Triangle(float3(0,0,0), float3(100,0,0), float3(0,100,50)), float4(1,0,0,1));
    // v.addFace(Triangle(float3(0,0,0), float3(100,0,0), float3(100,0,100)), float4(1,0,0,1));
    // v.addFace(Triangle(float3(0,0,0), float3(100,0,100), float3(0,0,100)), float4(1,0,0,1));

    //v.addGeometry(Obj.read("testdata/models/suzanne.obj.txt"));

    v.addGeometry(GLTF.read("testdata/models/gltf/cat.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/chicken.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/mushnub evolved.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/Locomotive Front.glb"));
    // v.addGeometry(GLTF.read("testdata/models/gltf/Yucca Plant.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/Fantasy Inn.glb"));

    v.rotate(0.degrees, 180.degrees, 0.degrees);

    auto block = v.voxelise(512, true);
    block.write("testdata/models/voxels.voxels-raw");
}
