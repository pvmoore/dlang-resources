module test_data;

import std.stdio                : writefln;
import std.format               : format;
import std.file                 : read;
import std.array                : appender;
import std.datetime.stopwatch   : StopWatch, AutoStart;
import std.range                : array;
import std.algorithm            : minElement, maxElement, each, map, sum;
import std.random               : uniform;
import std.typecons             : tuple, Tuple;

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

    //testCumulativeCounts();
    //testEntropyModel();
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
void testCumulativeCounts() {
    writefln("Testing CumulativeCounts ---------------------------------");
    {
        auto c = new CumulativeCounts(16); 
        c.add(11);
        c.add(6);
        c.add(8);
        c.add(7);
        c.add(15);

        c.dumpTree();

        assert(c.getCountByIndex(5) == 0);
        assert(c.getCountByIndex(6) == 1);
        assert(c.getCountByIndex(7) == 2);
        assert(c.getCountByIndex(8) == 3);
        assert(c.getCountByIndex(11) == 4);
        assert(c.getCountByIndex(13) == 4);
        assert(c.getCountByIndex(15) == 5);   
    }
    {
        auto c = new CumulativeCounts(16); 
        foreach(i; 0..16) {
            c.add(i);
        }
        c.add(11);
        c.add(6);
        c.add(8);
        c.add(7);
        c.add(15);

        assert(c.getCountByRange(0) == 0);
        assert(c.getCountByRange(1) == 1);
        assert(c.getCountByRange(2) == 2);
        assert(c.getCountByRange(3) == 3);
        assert(c.getCountByRange(4) == 4);
        assert(c.getCountByRange(5) == 5);
        assert(c.getCountByRange(6) == 6);
        assert(c.getCountByRange(7) == 6);
        assert(c.getCountByRange(8) == 7);
        assert(c.getCountByRange(9) == 7);
        assert(c.getCountByRange(10) == 8);
        assert(c.getCountByRange(11) == 8);
        assert(c.getCountByRange(12) == 9);
        assert(c.getCountByRange(13) == 10);
        assert(c.getCountByRange(14) == 11);
        assert(c.getCountByRange(15) == 11);
        assert(c.getCountByRange(16) == 12);
        assert(c.getCountByRange(17) == 13);
        assert(c.getCountByRange(18) == 14);
        assert(c.getCountByRange(19) == 15);
        assert(c.getCountByRange(20) == 15);

        c.dumpTree();
    }
    {   // check initialCount
        auto c1 = new CumulativeCounts(8);
        foreach(i; 0..8) {
            c1.add(i);
        }

        auto c2 = new CumulativeCounts(8, 1);
        c1.dumpTree();
        c2.dumpTree();

        assert(c1.peekCounts() == c2.peekCounts());
    }
    {   // check add() count > 1
        auto c1 = new CumulativeCounts(8);
        auto c2 = new CumulativeCounts(8);
        c1.add(3, 2);
        c2.add(3);
        c2.add(3);
        c1.dumpTree();
        c2.dumpTree();

        assert(c1.peekCounts() == c2.peekCounts());
    }
    {   // total
        auto c0 = new CumulativeCounts(8);
        assert(c0.getTotal() == 0);

        auto c1 = new CumulativeCounts(8, 1);
        assert(c1.getTotal() == 8);

        auto c2 = new CumulativeCounts(8, 1);
        c2.add(3, 7);
        assert(c2.getTotal() == 8+7);
    }
    {
        // fuzz test
        writefln("################ Fuzz test ################");
        
        void _run(uint num) {
            ulong[] counts = new ulong[num];
            auto c = new CumulativeCounts(num); 
            foreach(i; 0..num*uniform(1,10)) {
                uint index = uniform(0,num);
                counts[index]++;
                c.add(index);
            }
            c.dumpTree();

            writefln("counts:  %s", counts);
            ulong total = 0;
            foreach(i; 0..num) {
                total += counts[i];
                counts[i] = total;
            }
            writefln("weights: %s", counts);
            writefln("Checking ...");
            foreach(i; 0..num) {
                assert(counts[i] == c.getCountByIndex(i));
            }
            writefln("Correct");
        }

        _run(16);
        _run(33);
        _run(128);
    }
   
}
void testEntropyModel() {
    writefln("Testing testEntropyModel ---------------------------------");
    ulong[] frequencies = [1,1,1,1,1,1,2,2, 2,1,1,2,1,1,1,2];
    auto staticModel = new Order0StaticModel(frequencies);
    auto dynamicModel = new Order0DynamicModel(16);

    dynamicModel.getSymbolFromValue(11);
    dynamicModel.getSymbolFromValue(6);
    dynamicModel.getSymbolFromValue(15);
    dynamicModel.getSymbolFromValue(8);
    dynamicModel.getSymbolFromValue(7);
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
    auto s11 = staticModel.getSymbolFromValue(11);
    auto s12 = staticModel.getSymbolFromValue(12);
    auto s13 = staticModel.getSymbolFromValue(13);
    auto s14 = staticModel.getSymbolFromValue(14);
    auto s15 = staticModel.getSymbolFromValue(15);

    assert(s0 == MSymbol(0, 1, 21, 0));
    assert(s1 == MSymbol(1, 2, 21, 1));
    assert(s2 == MSymbol(2, 3, 21, 2));
    assert(s3 == MSymbol(3, 4, 21, 3));
    assert(s4 == MSymbol(4, 5, 21, 4));
    assert(s5 == MSymbol(5, 6, 21, 5));
    assert(s6 == MSymbol(6, 8, 21, 6));
    assert(s7 == MSymbol(8, 10, 21,7));
    assert(s8 == MSymbol(10, 12, 21, 8));
    assert(s9 == MSymbol(12, 13, 21, 9));
    assert(s10 == MSymbol(13, 14, 21, 10));
    assert(s11 == MSymbol(14, 16, 21, 11));
    assert(s12 == MSymbol(16, 17, 21, 12));
    assert(s13 == MSymbol(17, 18, 21, 13));
    assert(s14 == MSymbol(18, 19, 21, 14));
    assert(s15 == MSymbol(19, 21, 21, 15));

    assert(s0 == dynamicModel.peekSymbolFromValue(0));
    assert(s1 == dynamicModel.peekSymbolFromValue(1));
    assert(s2 == dynamicModel.peekSymbolFromValue(2));
    assert(s3 == dynamicModel.peekSymbolFromValue(3));
    assert(s4 == dynamicModel.peekSymbolFromValue(4));
    assert(s5 == dynamicModel.peekSymbolFromValue(5));
    assert(s6 == dynamicModel.peekSymbolFromValue(6));
    assert(s7 == dynamicModel.peekSymbolFromValue(7));
    assert(s8 == dynamicModel.peekSymbolFromValue(8));
    assert(s9 == dynamicModel.peekSymbolFromValue(9));
    assert(s10 == dynamicModel.peekSymbolFromValue(10));
    assert(s11 == dynamicModel.peekSymbolFromValue(11));
    assert(s12 == dynamicModel.peekSymbolFromValue(12));
    assert(s13 == dynamicModel.peekSymbolFromValue(13));
    assert(s14 == dynamicModel.peekSymbolFromValue(14));
    assert(s15 == dynamicModel.peekSymbolFromValue(15));

    auto sr0 = staticModel.getSymbolFromRange(0);
    auto sr1 = staticModel.getSymbolFromRange(1);
    auto sr2 = staticModel.getSymbolFromRange(2);
    auto sr3 = staticModel.getSymbolFromRange(3);
    auto sr4 = staticModel.getSymbolFromRange(4);
    auto sr5 = staticModel.getSymbolFromRange(5);
    auto sr6 = staticModel.getSymbolFromRange(6);
    auto sr7 = staticModel.getSymbolFromRange(7);
    auto sr8 = staticModel.getSymbolFromRange(8);
    auto sr9 = staticModel.getSymbolFromRange(9);
    auto sr10 = staticModel.getSymbolFromRange(10);
    auto sr11 = staticModel.getSymbolFromRange(11);
    auto sr12 = staticModel.getSymbolFromRange(12);
    auto sr13 = staticModel.getSymbolFromRange(13);
    auto sr14 = staticModel.getSymbolFromRange(14);
    auto sr15 = staticModel.getSymbolFromRange(15);
    auto sr16 = staticModel.getSymbolFromRange(16);
    auto sr17 = staticModel.getSymbolFromRange(17);
    auto sr18 = staticModel.getSymbolFromRange(18);
    auto sr19 = staticModel.getSymbolFromRange(19);
    auto sr20 = staticModel.getSymbolFromRange(20);

    assert(sr0 == MSymbol(0, 1, 21, 0));
    assert(sr1 == MSymbol(1, 2, 21, 1));
    assert(sr2 == MSymbol(2, 3, 21, 2));
    assert(sr3 == MSymbol(3, 4, 21, 3));
    assert(sr4 == MSymbol(4, 5, 21, 4));
    assert(sr5 == MSymbol(5, 6, 21, 5));
    assert(sr6 == MSymbol(6, 8, 21, 6));
    assert(sr7 == MSymbol(6, 8, 21, 6));
    assert(sr8 == MSymbol(8, 10, 21, 7));
    assert(sr9 == MSymbol(8, 10, 21, 7));
    assert(sr10 == MSymbol(10, 12, 21, 8));
    assert(sr11 == MSymbol(10, 12, 21, 8));
    assert(sr12 == MSymbol(12, 13, 21, 9));
    assert(sr13 == MSymbol(13, 14, 21, 10));
    assert(sr14 == MSymbol(14, 16, 21, 11));
    assert(sr15 == MSymbol(14, 16, 21, 11));
    assert(sr16 == MSymbol(16, 17, 21, 12));
    assert(sr17 == MSymbol(17, 18, 21, 13));
    assert(sr18 == MSymbol(18, 19, 21, 14));
    assert(sr19 == MSymbol(19, 21, 21, 15));
    assert(sr20 == MSymbol(19, 21, 21, 15));

    assert(sr0 == dynamicModel.peekSymbolFromRange(0));
    assert(sr1 == dynamicModel.peekSymbolFromRange(1));
    assert(sr2 == dynamicModel.peekSymbolFromRange(2));
    assert(sr3 == dynamicModel.peekSymbolFromRange(3));
    assert(sr4 == dynamicModel.peekSymbolFromRange(4));
    assert(sr5 == dynamicModel.peekSymbolFromRange(5));
    assert(sr6 == dynamicModel.peekSymbolFromRange(6));
    assert(sr7 == dynamicModel.peekSymbolFromRange(7));
    assert(sr8 == dynamicModel.peekSymbolFromRange(8));
    assert(sr9 == dynamicModel.peekSymbolFromRange(9));
    assert(sr10 == dynamicModel.peekSymbolFromRange(10));
    assert(sr11 == dynamicModel.peekSymbolFromRange(11));
    assert(sr12 == dynamicModel.peekSymbolFromRange(12));
    assert(sr13 == dynamicModel.peekSymbolFromRange(13));
    assert(sr14 == dynamicModel.peekSymbolFromRange(14));
    assert(sr15 == dynamicModel.peekSymbolFromRange(15));
    assert(sr16 == dynamicModel.peekSymbolFromRange(16));
    assert(sr17 == dynamicModel.peekSymbolFromRange(17));
    assert(sr18 == dynamicModel.peekSymbolFromRange(18));
    assert(sr19 == dynamicModel.peekSymbolFromRange(19));
    assert(sr20 == dynamicModel.peekSymbolFromRange(20));

    assert(staticModel.getScale() == 21);
    assert(staticModel.getScale() == dynamicModel.getScale());
}
void testArithmeticCoder() {
    writefln("Testing ArithmeticCoder ---------------------------------");

    StopWatch encodeTime;
    StopWatch decodeTime;

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

        encodeTime.start();
        coder.beginEncoding();
        foreach(b; data) {
            coder.encode(w, b);
        }
        coder.endEncoding(w);
        encodeTime.stop();
        encodedData = outStream.data;
        return numBits;
    }
    void _decode(ArithmeticCoder coder, ubyte[] originalData, ubyte[] encodedData) {
        writefln("    decoding");
        auto br = new ByteReader(encodedData);
        auto r  = new BitReader(() { return br.read!ubyte; });
        decodeTime.start();
        coder.beginDecoding(r);
        foreach(i; 0..originalData.length) {
            int value = coder.decode(r);
            assert(originalData[i] == cast(ubyte)value, "i=%s expected = %s, actual = %s".format(i, originalData[i], value));
        }
        coder.endDecoding();
        decodeTime.stop();
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

        data = cast(ubyte[])read("testdata/book2");
        _doTest!Order0DynamicModel("book2", data);
    }
    _doStaticModelTests();
    _doDynamicModelTests();

    writefln("encode time %s ms", encodeTime.peek().total!"nsecs"/1_000_000.0); // ~70 ms
    writefln("decode time %s ms", decodeTime.peek().total!"nsecs"/1_000_000.0); // ~95 ms
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
