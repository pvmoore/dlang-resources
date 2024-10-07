module test_data;

import std.stdio                : writefln;
import std.format               : format;
import std.file                 : read;
import std.array                : appender;
import std.datetime.stopwatch   : StopWatch;
import std.range                : array;
import std.algorithm            : minElement, maxElement, each, map, sum;

import maths    : entropyBits;
import common   : as, BitWriter, BitReader, ByteReader;

import resources;

void testData() {
    //test7Zip();
    //testLZMA();
    //testPDC();
    //testPDC2();
    //testPDC3();
    //testLZ4();
    //testDeflate();
    //testZip();
    //testDedupe();

    testEntropyModel();
    testArithmeticCoder();
    //testHuffmanCoder();
}

private:

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
void testDedupe() {
    import resources.data.experimental.dedupe;

    DeDupe dd = new DeDupe();
    dd.run("testdata/bib");

    writefln("done");
}
void testPDC() {
    import resources.data.experimental.pdc;
    writefln("#######################################");
    writefln("Testing PDC");
    writefln("#######################################");
    auto pdc = new PDC("testdata/geo");
}
void testPDC2() {
    import resources.data.experimental.pdc2;
    writefln("#######################################");
    writefln("Testing PDC2");
    writefln("#######################################");
    auto pdc2 = new PDC2("testdata/bib");
    auto bytes = pdc2.encode();
}
void testPDC3() {
    import resources.data.experimental.pdc3;
    writefln("#######################################");
    writefln("Testing PDC3");
    writefln("#######################################");
    auto pdc3 = new PDC3("testdata/bib");
    pdc3.encode();
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
void testEntropyModel() {
    writefln("Testing testEntropyModel ---------------------------------");
    ulong[] frequencies = [1,1,1,1, 1,1,1,1, 1,1,1];
    auto staticModel = new Order0StaticModel(frequencies);
    auto dynamicModel = new Order0DynamicModel(11);
    staticModel.dumpRanges();
    dynamicModel.dumpRanges();

    auto s0 = staticModel.getSymbolFromValue(0);
    auto s1 = staticModel.getSymbolFromValue(1);
    auto s2 = staticModel.getSymbolFromValue(2);
    auto s3 = staticModel.getSymbolFromValue(3);
    auto s4 = staticModel.getSymbolFromValue(4);
    auto s5 = staticModel.getSymbolFromValue(5);
    auto s6 = staticModel.getSymbolFromValue(6);
    auto s7 = staticModel.getSymbolFromValue(7);
    auto s8 = staticModel.getSymbolFromValue(8);
    auto s9 = staticModel.getSymbolFromValue(9);
    auto s10 = staticModel.getSymbolFromValue(10);

    auto d0 = dynamicModel.peekSymbolFromValue(0);
    auto d1 = dynamicModel.peekSymbolFromValue(1);
    auto d2 = dynamicModel.peekSymbolFromValue(2);
    auto d3 = dynamicModel.peekSymbolFromValue(3);
    auto d4 = dynamicModel.peekSymbolFromValue(4);
    auto d5 = dynamicModel.peekSymbolFromValue(5);
    auto d6 = dynamicModel.peekSymbolFromValue(6);
    auto d7 = dynamicModel.peekSymbolFromValue(7);
    auto d8 = dynamicModel.peekSymbolFromValue(8);
    auto d9 = dynamicModel.peekSymbolFromValue(9);
    auto d10 = dynamicModel.peekSymbolFromValue(10);

    assert(s0 == d0);
    assert(s1 == d1);
    assert(s2 == d2);
    assert(s3 == d3);
    assert(s4 == d4);
    assert(s5 == d5);
    assert(s6 == d6);
    assert(s7 == d7);
    assert(s8 == d8);
    assert(s9 == d9);
    assert(s10 == d10);

    auto sr0 = staticModel.getSymbolFromRange(0);
    auto dr0 = dynamicModel.peekSymbolFromRange(0);

    assert(sr0 == dr0);
}
void testArithmeticCoder() {
    writefln("Testing ArithmeticCoder ---------------------------------");

    ulong[] _calcFrequences(ubyte[] data, uint scale) {
        ulong[] frequencies = new ulong[scale];
        foreach(b; data) {
            frequencies[b]++;
        }
        return frequencies;
    }
    ulong _encode(ArithmeticCoder coder, ubyte[] data, ref ubyte[] encodedData) {
        writefln("    encoding");
        ulong numBits;
        auto outStream = appender!(ubyte[]);
        auto w = new BitWriter((it) {numBits+=8; outStream~= it; });

        coder.beginEncoding();
        foreach(b; data) {
            coder.encode(w, b);
        }
        coder.endEncoding(w);
        encodedData = outStream.data;
        return numBits;
    }
    void _decode(ArithmeticCoder coder, ubyte[] originalData, ubyte[] encodedData) {
        writefln("    decoding");
        auto br = new ByteReader(encodedData);
        auto r  = new BitReader(() { return br.read!ubyte; });
        coder.beginDecoding(r);
        foreach(i; 0..originalData.length) {
            int value = coder.decode(r);
            assert(originalData[i] == cast(ubyte)value, "i=%s expected = %s, actual = %s".format(i, originalData[i], value));
        }
        coder.endDecoding();
        writefln("    decode succeeded");
    }
    void _doTest(T : EntropyModel)(string name, ubyte[] data) {

        static if(is(T==Order0StaticModel)) {
            EntropyModel encodeModel = new Order0StaticModel(_calcFrequences(data, 256));
            EntropyModel decodeModel = new Order0StaticModel(_calcFrequences(data, 256));
        } else {
            EntropyModel encodeModel = new Order0DynamicModel(256);
            EntropyModel decodeModel = new Order0DynamicModel(256);
        }

        ArithmeticCoder encoder = new ArithmeticCoder(encodeModel);
        ArithmeticCoder decoder = new ArithmeticCoder(decodeModel);

        writefln("  '%s'", name);
        writefln("    length = %s", data.length);

        ubyte[] encodedData;
        auto numBits = _encode(encoder, data, encodedData);

        writefln("    coder entropy   = %s bits (%s bytes)", numBits, numBits/8);

        _decode(decoder, data, encodedData);
    }
    void _doStaticModelTests() {
        writefln("Order0StaticModel");
        ubyte[] data = [];
        _doTest!Order0StaticModel("empty stream", data);
        data = [0];
        _doTest!Order0StaticModel("single byte", data);
        data = [0,1,2,3];
        _doTest!Order0StaticModel("short sequence", data);
        data = cast(ubyte[])read("testdata/bib");
        _doTest!Order0StaticModel("bib", data);
    }
    void _doDynamicModelTests() {
        writefln("Order0DynamicModel");
        ubyte[] data = [];
        _doTest!Order0DynamicModel("empty stream", data);
        data = [0];
        _doTest!Order0DynamicModel("single byte", data);
        data = [0,1,2,3];
        _doTest!Order0DynamicModel("short sequence", data);
        data = cast(ubyte[])read("testdata/bib");
        _doTest!Order0DynamicModel("bib", data);
    }
    _doStaticModelTests();
    _doDynamicModelTests();
}
void testHuffmanCoder() {
    writefln("Testing HuffmanCoder ---------------------------------");

    uint[] _calcFrequences(ubyte[] data, uint scale) {
        uint[] frequencies = new uint[scale];
        foreach(b; data) {
            frequencies[b]++;
        }
        return frequencies;
    }
    {   
        writefln("  Testing bib");
        ubyte[] bib = cast(ubyte[])read("testdata/bib");
        uint[] frequencies = _calcFrequences(bib, 256);

        auto tree = new HuffmanCoder().createFromFrequencies(frequencies);
        //writefln("%s", tree);
        writefln("    bit lengths = %s -> %s", tree.getShortestBitLength, tree.getLongestBitLength);

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
        writefln("    Huffman entropy = %s bits (%s bytes)", numBits, numBits/8);

        // check the encoded stream
        auto br = new ByteReader(outStream.data);
        auto r  = new BitReader(() { return br.read!ubyte; });
        foreach(i; 0..bib.length) {
            int value = tree.decode(r);
            assert(bib[i] == cast(ubyte)value);
        }
        writefln("    Huffman decode succeeded");
    }
}
void testRangeCoder() {

}
void testPennyDropCoder() {

}
