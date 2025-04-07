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

import maths        : entropyBits;
import common.io    : BitWriter, BitReader, ByteReader; 
import common.utils : as, className;

import resources;

void testData() {
    //test7Zip();
    //testLZMA();
    //testPDC();
    //testPDC2();
    testPDC3();
    //testLZ4();
    //testDeflate();
    //testZip();
    //testDedupe();

    //testLinearModel();
    //testOrder1Model();
    //testCumulativeCounts();
    //testEntropyModel();
    //testArithmeticCoder();

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
void testLinearModel() {
    writefln("Testing LinearModel ---------------------------------");
    {
        auto s = new Order0StaticModel([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);
        auto l  = new LinearModel(16);

        assert(s.getScale() == l.getScale());

        foreach(i; 0..16) {
            assert(s.getSymbolFromIndex(i) == l.getSymbolFromIndex(i));
            assert(s.getSymbolFromRange(i) == l.getSymbolFromRange(i));
        }
    }
    {   // addSymbols
        auto l  = new LinearModel(8);
        assert(l.getScale() == 8);

        l.addSymbols(2);
        assert(l.getScale() == 10);

        foreach(i; 0..10) {
            assert(l.getSymbolFromIndex(i) == MSymbol(i, i+1, 10, i));
        }
    }
}
void testOrder1Model() {
    writefln("Testing Order1Model ---------------------------------");
    
    {
        auto m = new Order1Model(16, 1);

        auto s5 = m.getSymbolFromIndex(5);
        assert(s5 == MSymbol(5,6,16,5));

        auto s5_2 = m.getSymbolFromIndex(5);
        assert(s5_2 == MSymbol(5,6,16,5));

        auto s5_3 = m.getSymbolFromIndex(5);
        assert(s5_3 == MSymbol(5,7,17,5));

        writefln("%s", s5_3);
    }
}
void testCumulativeCounts() {
    writefln("Testing CumulativeCounts ---------------------------------");
    {
        auto c = new CumulativeCounts(16, 0); 
        c.add(11);
        c.add(6);
        c.add(8);
        c.add(7);
        c.add(15);

        c.dumpTree();
        // 0 0 0 0 0 0 1 2  3 0 0 4 0 0 0 5

        writefln("===> %s", c.getSymbolFromIndex(5));

        assert(c.getSymbolFromIndex(0) == MSymbol(0, 0, 5, 0));
        assert(c.getSymbolFromIndex(1) == MSymbol(0, 0, 5, 1));
        assert(c.getSymbolFromIndex(2) == MSymbol(0, 0, 5, 2));
        assert(c.getSymbolFromIndex(3) == MSymbol(0, 0, 5, 3));
        assert(c.getSymbolFromIndex(4) == MSymbol(0, 0, 5, 4));
        assert(c.getSymbolFromIndex(5) == MSymbol(0, 0, 5, 5));
        assert(c.getSymbolFromIndex(6) == MSymbol(0, 1, 5, 6));
        assert(c.getSymbolFromIndex(7) == MSymbol(1, 2, 5, 7));
        assert(c.getSymbolFromIndex(8) == MSymbol(2, 3, 5, 8));
        assert(c.getSymbolFromIndex(9) == MSymbol(3, 3, 5, 9));
        assert(c.getSymbolFromIndex(10) == MSymbol(3, 3, 5, 10));
        assert(c.getSymbolFromIndex(11) == MSymbol(3, 4, 5, 11));
        assert(c.getSymbolFromIndex(12) == MSymbol(4, 4, 5, 12));
        assert(c.getSymbolFromIndex(13) == MSymbol(4, 4, 5, 13));
        assert(c.getSymbolFromIndex(14) == MSymbol(4, 4, 5, 14));
        assert(c.getSymbolFromIndex(15) == MSymbol(4, 5, 5, 15));  
    }
    {
        auto c = new CumulativeCounts(16, 1); 
        c.add(11);
        c.add(6);
        c.add(8);
        c.add(7);
        c.add(15);

        c.dumpTree();

        assert(c.getSymbolFromIndex(0) == MSymbol(0, 1, 21, 0));
        assert(c.getSymbolFromIndex(1) == MSymbol(1, 2, 21, 1));
        assert(c.getSymbolFromIndex(2) == MSymbol(2, 3, 21, 2));
        assert(c.getSymbolFromIndex(3) == MSymbol(3, 4, 21, 3));
        assert(c.getSymbolFromIndex(4) == MSymbol(4, 5, 21, 4));
        assert(c.getSymbolFromIndex(5) == MSymbol(5, 6, 21, 5));
        assert(c.getSymbolFromIndex(6) == MSymbol(6, 8, 21, 6));
        assert(c.getSymbolFromIndex(7) == MSymbol(8, 10, 21, 7));
        assert(c.getSymbolFromIndex(8) == MSymbol(10, 12, 21, 8));
        assert(c.getSymbolFromIndex(9) == MSymbol(12, 13, 21, 9));
        assert(c.getSymbolFromIndex(10) == MSymbol(13, 14, 21, 10));
        assert(c.getSymbolFromIndex(11) == MSymbol(14, 16, 21, 11));
        assert(c.getSymbolFromIndex(12) == MSymbol(16, 17, 21, 12));
        assert(c.getSymbolFromIndex(13) == MSymbol(17, 18, 21, 13));
        assert(c.getSymbolFromIndex(14) == MSymbol(18, 19, 21, 14));
        assert(c.getSymbolFromIndex(15) == MSymbol(19, 21, 21, 15)); 
    }
    {   // check initialCount
        auto c1 = new CumulativeCounts(8, 0);
        foreach(i; 0..8) {
            c1.add(i);
        }

        auto c2 = new CumulativeCounts(8, 1);
        c1.dumpTree();
        c2.dumpTree();

        assert(c1.peekCounts() == c2.peekCounts());
    }
    {
        auto c = new CumulativeCounts(16, 1); 
        c.add(11);
        c.add(6);
        c.add(8);
        c.add(7);
        c.add(15);

        assert(c.getSymbolFromRange(0) == MSymbol(0, 1, 21, 0));
        assert(c.getSymbolFromRange(1) == MSymbol(1, 2, 21, 1));
        assert(c.getSymbolFromRange(2) == MSymbol(2, 3, 21, 2));
        assert(c.getSymbolFromRange(3) == MSymbol(3, 4, 21, 3));
        assert(c.getSymbolFromRange(4) == MSymbol(4, 5, 21, 4));
        assert(c.getSymbolFromRange(5) == MSymbol(5, 6, 21, 5));
        assert(c.getSymbolFromRange(6) == MSymbol(6, 8, 21, 6));
        assert(c.getSymbolFromRange(7) == MSymbol(6, 8, 21, 6));
        assert(c.getSymbolFromRange(8) == MSymbol(8, 10, 21, 7));
        assert(c.getSymbolFromRange(9) == MSymbol(8, 10, 21, 7));
        assert(c.getSymbolFromRange(10) == MSymbol(10, 12, 21, 8));
        assert(c.getSymbolFromRange(11) == MSymbol(10, 12, 21, 8));
        assert(c.getSymbolFromRange(12) == MSymbol(12, 13, 21, 9));
        assert(c.getSymbolFromRange(13) == MSymbol(13, 14, 21, 10));
        assert(c.getSymbolFromRange(14) == MSymbol(14, 16, 21, 11));
        assert(c.getSymbolFromRange(15) == MSymbol(14, 16, 21, 11));
        assert(c.getSymbolFromRange(16) == MSymbol(16, 17, 21, 12));
        assert(c.getSymbolFromRange(17) == MSymbol(17, 18, 21, 13));
        assert(c.getSymbolFromRange(18) == MSymbol(18, 19, 21, 14));
        assert(c.getSymbolFromRange(19) == MSymbol(19, 21, 21, 15));
        assert(c.getSymbolFromRange(20) == MSymbol(19, 21, 21, 15));
    }
    {   // check add() count > 1
        auto c1 = new CumulativeCounts(8, 0);
        auto c2 = new CumulativeCounts(8, 0);
        c1.add(3, 2);
        c2.add(3);
        c2.add(3);
        c1.dumpTree();
        c2.dumpTree();

        assert(c1.peekCounts() == c2.peekCounts());
    }
    {   // total
        auto c0 = new CumulativeCounts(8, 0);
        assert(c0.getTotal() == 0);

        auto c1 = new CumulativeCounts(8, 1);
        assert(c1.getTotal() == 8);

        auto c2 = new CumulativeCounts(8, 1);
        c2.add(3, 7);
        assert(c2.getTotal() == 8+7);
    }
    {   // expandBy
        auto c = new CumulativeCounts(9, 1);
        assert(c.getNumCounts()==9);
        assert(c.getCapacity()==16);
        assert(c.getTotal() == 9);
        assert(c.peekCounts()      == [1,1,1,1,1,1,1,1,1]);
        assert(c.peekWeightsLow()  == [0,1,2,3,4,5,6,7,8]);
        assert(c.peekWeightsHigh() == [1,2,3,4,5,6,7,8,9]);

        c.expandBy(1, 0); 
        c.dumpTree();
        assert(c.getNumCounts()==10);
        assert(c.getCapacity()==16);
        assert(c.getTotal() == 9);
        assert(c.peekCounts()      == [1,1,1,1, 1,1,1,1, 1,0]);
        assert(c.peekWeightsLow()  == [0,1,2,3,4,5,6,7,8,9]);
        assert(c.peekWeightsHigh() == [1,2,3,4,5,6,7,8,9,9]);

        c.expandBy(1, 1);
        c.dumpTree();
        assert(c.getNumCounts()==11);
        assert(c.getCapacity()==16);
        assert(c.getTotal() == 10);
        assert(c.peekCounts()      == [1,1,1,1, 1,1,1,1, 1,0,1]);
        assert(c.peekWeightsLow()  == [0,1,2,3,4,5,6,7,8,9,9]);
        assert(c.peekWeightsHigh() == [1,2,3,4,5,6,7,8,9,9,10]);

        c.expandBy(5, 1);
        c.dumpTree();
        assert(c.getNumCounts()==16);
        assert(c.getCapacity()==16);
        assert(c.getTotal() == 15);
        assert(c.peekCounts()      == [1,1,1,1, 1,1,1,1, 1, 0, 1, 1, 1, 1, 1, 1]);
        assert(c.peekWeightsLow()  == [0,1,2,3, 4,5,6,7, 8, 9, 9,10,11,12,13,14]);
        assert(c.peekWeightsHigh() == [1,2,3,4, 5,6,7,8, 9, 9,10,11,12,13,14,15]);

        c.expandBy(3, 1);
        c.dumpTree();
        assert(c.getNumCounts()==19);
        assert(c.getCapacity()==32);
        assert(c.getTotal() == 18);
        assert(c.peekCounts()      == [1,1,1,1, 1,1,1,1, 1, 0, 1, 1, 1, 1, 1, 1, 1,1,1]);
        assert(c.peekWeightsLow()  == [0,1,2,3, 4,5,6,7, 8, 9, 9,10,11,12,13,14, 15,16,17]);
        assert(c.peekWeightsHigh() == [1,2,3,4, 5,6,7,8, 9, 9,10,11,12,13,14,15, 16,17,18]);
    }
    {
        // fuzz test
        writefln("################ Fuzz test ################");
        
        void _run(uint num) {
            ulong[] counts = new ulong[num];
            auto c = new CumulativeCounts(num, 0); 
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
                assert(counts[i] == c.getSymbolFromIndex(i).high);
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
    auto staticModel = new FastOrder0StaticModel(frequencies);
    auto dynamicModel = new FastOrder0DynamicModel(16);

    dynamicModel.getSymbolFromIndex(11);
    dynamicModel.getSymbolFromIndex(6);
    dynamicModel.getSymbolFromIndex(15);
    dynamicModel.getSymbolFromIndex(8);
    dynamicModel.getSymbolFromIndex(7);
    staticModel.dumpRanges();
    dynamicModel.dumpRanges();

    auto s0 = staticModel.getSymbolFromIndex(0);
    auto s1 = staticModel.getSymbolFromIndex(1);
    auto s2 = staticModel.getSymbolFromIndex(2);
    auto s3 = staticModel.getSymbolFromIndex(3);
    auto s4 = staticModel.getSymbolFromIndex(4);
    auto s5 = staticModel.getSymbolFromIndex(5);
    auto s6 = staticModel.getSymbolFromIndex(6);
    auto s7 = staticModel.getSymbolFromIndex(7);
    auto s8 = staticModel.getSymbolFromIndex(8);
    auto s9 = staticModel.getSymbolFromIndex(9);
    auto s10 = staticModel.getSymbolFromIndex(10);
    auto s11 = staticModel.getSymbolFromIndex(11);
    auto s12 = staticModel.getSymbolFromIndex(12);
    auto s13 = staticModel.getSymbolFromIndex(13);
    auto s14 = staticModel.getSymbolFromIndex(14);
    auto s15 = staticModel.getSymbolFromIndex(15);

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

    assert(s0 == dynamicModel.peekSymbolFromIndex(0));
    assert(s1 == dynamicModel.peekSymbolFromIndex(1));
    assert(s2 == dynamicModel.peekSymbolFromIndex(2));
    assert(s3 == dynamicModel.peekSymbolFromIndex(3));
    assert(s4 == dynamicModel.peekSymbolFromIndex(4));
    assert(s5 == dynamicModel.peekSymbolFromIndex(5));
    assert(s6 == dynamicModel.peekSymbolFromIndex(6));
    assert(s7 == dynamicModel.peekSymbolFromIndex(7));
    assert(s8 == dynamicModel.peekSymbolFromIndex(8));
    assert(s9 == dynamicModel.peekSymbolFromIndex(9));
    assert(s10 == dynamicModel.peekSymbolFromIndex(10));
    assert(s11 == dynamicModel.peekSymbolFromIndex(11));
    assert(s12 == dynamicModel.peekSymbolFromIndex(12));
    assert(s13 == dynamicModel.peekSymbolFromIndex(13));
    assert(s14 == dynamicModel.peekSymbolFromIndex(14));
    assert(s15 == dynamicModel.peekSymbolFromIndex(15));

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
        } else static if(is(T==FastOrder0StaticModel)) {
            EntropyModel encodeModel = new FastOrder0StaticModel(_calcFrequences(data, 256));
            EntropyModel decodeModel = new FastOrder0StaticModel(_calcFrequences(data, 256));
        } else static if(is(T==FastOrder0DynamicModel)) {
            EntropyModel encodeModel = new FastOrder0DynamicModel(256, 20);
            EntropyModel decodeModel = new FastOrder0DynamicModel(256, 20);
        } else static if(is(T==Order0DynamicModel)) {
            EntropyModel encodeModel = new Order0DynamicModel(256, 20);
            EntropyModel decodeModel = new Order0DynamicModel(256, 20);
        } else static if(is(T==Order1Model)) {
            EntropyModel encodeModel = new Order1Model(256, 1);
            EntropyModel decodeModel = new Order1Model(256, 1);
        } else {
            throwIf(true, "Unrecognised EntropyModel");
        }

        ArithmeticCoder encoder = new ArithmeticCoder(encodeModel);
        ArithmeticCoder decoder = new ArithmeticCoder(decodeModel);

        writefln("  '%s'", name);
        writefln("    length = %s", data.length);

        ubyte[] encodedData;
        auto numBits = _encode(encoder, data, encodedData);

        writefln("    coder entropy = %s bits (%s bytes)", numBits, numBits/8);

        _decode(decoder, data, encodedData);
    }
    ubyte[] bib = cast(ubyte[])read("testdata/bib");
    ubyte[] book2 = cast(ubyte[])read("testdata/book2");
    void _doTests(T : EntropyModel)() {
        writefln("%s", className!T);
        _doTest!T("empty stream", []);
        _doTest!T("single byte", [0]);
        _doTest!T("short sequence", [0,1,2,3]);
        _doTest!T("bib", bib);
        _doTest!T("book2", book2);
    }
    _doTests!Order0StaticModel();
    _doTests!Order0DynamicModel();
    writefln("Standard version:");
    writefln("encode time %s ms", encodeTime.peek().total!"nsecs"/1_000_000.0); // ~90 ms
    writefln("decode time %s ms", decodeTime.peek().total!"nsecs"/1_000_000.0); // ~145 ms
    
    encodeTime.reset();
    decodeTime.reset();

    _doTests!FastOrder0StaticModel();
    _doTests!FastOrder0DynamicModel();
    writefln("Optimised version:");
    writefln("encode time %s ms", encodeTime.peek().total!"nsecs"/1_000_000.0); // ~82 ms
    writefln("decode time %s ms", decodeTime.peek().total!"nsecs"/1_000_000.0); // ~80 ms

    _doTests!Order1Model();
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
