module test_images;

import std.stdio : writefln;

void testWebP() {
    writefln("#######################################");
    writefln("Testing WebP");
    writefln("#######################################");
    
    import resources.image.webp;

    auto lossless = WebP.read("testdata/webp/2_webp_ll.webp");
    writefln("webp = %s", lossless);

    // auto lossy = WebP.read("testdata/webp/1.sm.webp");
    // writefln("webp = %s", lossy);
}
