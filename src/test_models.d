module test_models;

import std.stdio : writefln;

import resources : Obj;
import resources.models.gltf;
import resources.models.magicavoxel.Vox;
import resources.models.converters.Voxeliser;

import maths : Triangle, float3, float4, degrees;

void testModels() {
    testVox();
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

void testVoxeliser() {
    writefln("#######################################");
    writefln("Testing Voxeliser");
    writefln("#######################################");

    Voxeliser v = new Voxeliser;

    // v.addFace(Triangle(float3(0,0,0), float3(100,0,0), float3(0,100,50)), float4(1,0,0,1));
    // v.addFace(Triangle(float3(0,0,0), float3(100,0,0), float3(100,0,100)), float4(1,0,0,1));
    // v.addFace(Triangle(float3(0,0,0), float3(100,0,100), float3(0,0,100)), float4(1,0,0,1));

    //v.addGeometry(Obj.read("testdata/models/suzanne.obj.txt"));

    //v.addGeometry(GLTF.read("testdata/models/gltf/cat.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/chicken.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/mushnub evolved.glb"));
    //v.addGeometry(GLTF.read("testdata/models/gltf/Locomotive Front.glb"));
    // v.addGeometry(GLTF.read("testdata/models/gltf/Yucca Plant.glb"));
    v.addGeometry(GLTF.read("testdata/models/gltf/Fantasy Inn.glb"));

    v.rotate(0.degrees, 180.degrees, 0.degrees);

    v.voxelise(512, true);
    v.write("testdata/models/voxels.voxels-raw");
}
