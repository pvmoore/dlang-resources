module test_models;

import std.stdio : writefln;

import resources.models.magicavoxel.Vox;

void testModels() {
    testVox();
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
