module test_data;

import std.stdio                : writefln;
import std.format               : format;
import std.file                 : read;
import std.array                : appender;
import std.datetime.stopwatch   : StopWatch;
import std.range                : array;
import std.algorithm            : minElement, maxElement, each, map, sum;

import maths    : entropyBits;
import common   : BitWriter, BitReader, ByteReader;

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

    testArithmeticCoder();
    testHuffmanCoder();
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
            assert(originalData[i] == cast(ubyte)value, "i=%s".format(i));
        }
        coder.endDecoding();
        writefln("    decode succeeded");
    }
    void _doTest(string name, ubyte[] data) {
        writefln("  Testing %s", name);
        ulong[] frequencies = _calcFrequences(data, 256);

        writefln("    length       = %s", data.length);
        writefln("    Lowest freq  = %s", frequencies.minElement);
        writefln("    Largest freq = %s", frequencies.maxElement);

        auto coder = new ArithmeticCoder(new Order0StaticModel(frequencies));

        ubyte[] encodedData;
        auto numBits = _encode(coder, data, encodedData);
        auto optimalEntropy = data.map!(it=>entropyBits(frequencies[it], data.length)).sum();

        writefln("    coder entropy   = %s bits (%s bytes)", numBits, numBits/8);
        writefln("    optimal entropy = %s bits", optimalEntropy);

        _decode(coder, data, encodedData);
    }
    _doTest("empty stream", []);
    _doTest("single byte", [0]);
    _doTest("short sequence", [0,1,2,3]);
    _doTest("bib", cast(ubyte[])read("testdata/bib"));
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
