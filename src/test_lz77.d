module test_lz77;

import std.stdio    : writefln;
import std.format   : format;
import std.file     : read;
import std.traits   : EnumMembers;
import common.utils : as;
import resources.algorithms.lz77.LZ77;

void testLZ77() {
    writefln("#######################################");
    writefln("Testing LZ77");
    writefln("#######################################");

    //enum STRATEGY = LZ77Strategy.NAIVE;                 // 13600ms
    //enum STRATEGY = LZ77Strategy.LARGE_HASH;          // 950ms
    //enum STRATEGY = LZ77Strategy.HASH_AND_LINKS_2;    // 720ms
    enum STRATEGY = LZ77Strategy.HASH_AND_LINKS_3;    // 330ms

    foreach(s; EnumMembers!LZ77Strategy) {
        writefln("Testing %s", s);
    }

    debug {
        unitTests!STRATEGY();   
        wholeFileTests!STRATEGY(); 
    } else { 
        benchmark!STRATEGY();
    }
}

private:
//──────────────────────────────────────────────────────────────────────────────────────────────────

void benchmark(LZ77Strategy STRATEGY)() {
    writefln("Benchmarking LZ77");
    import std.datetime.stopwatch : StopWatch, AutoStart;

    enum WINDOW_SIZE         = 32768;
    enum MAX_MATCH_LENGTH    = 32768;
    enum MAX_LITERALS_LENGTH = 32;

    auto lz = new LZ77!STRATEGY(WINDOW_SIZE, MAX_MATCH_LENGTH, MAX_LITERALS_LENGTH, (index, distance, length) { return length; }, (index, literals) {});
    StopWatch w = StopWatch(AutoStart.yes);

    enum COUNT = 5;
    foreach(i; 0..COUNT) {
        //lz.encodeFile("testdata/bib");    // 111,261    7ms
        //lz.encodeFile("testdata/book2");    //  610,856  35ms
        lz.encodeFile("testdata/bible.txt");  // 4,047,392  220ms
    }
    w.stop();
    auto ns = w.peek().total!"nsecs"/1_000_000.0;
    writefln("time = %s ms, (%s total)", ns/COUNT, ns);

}
void unitTests(LZ77Strategy STRATEGY)() {
    TestArgs args = {
        windowSize: 8, 
        maxMatchLength: 8, 
        maxLiteralsLength: 8,
    };
    auto tester = new Test!STRATEGY(args);

    TestArgs args2 = {
        windowSize: 32, 
        maxMatchLength: 8, 
        maxLiteralsLength: 8,
    };
    auto tester2 = new Test!STRATEGY(args2);

    if(false) {

        tester.test("aaaa", [Match(1, 0, 3)], [Literals(0, "a")]);
        return;
    }

    tester.test("", [], []);
    tester.test("a", [], [Literals(0, "a")]);
    tester.test("aa", [], [Literals(0, "aa")]);

    static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_3) {
        tester.test("aaaa", [Match(1, 0, 3)], [Literals(0, "a")]);
    } else {
        tester.test("aaa", [Match(1, 0, 2)], [Literals(0, "a")]);
    }

    //                     111111
    //           0123456789012345
    tester.test("abracadabra", [Match(7, 6, 4)], [Literals(0, "abracad")]);

    //                     111111
    //           0123456789012345
    tester.test("oooooooooooo", [Match(1, 0, 8), Match(9, 0, 3)], [Literals(0, "o")]);

    //                     1111111
    //           01234567890123456
    tester.test("abababababababab!", [Match(2, 1, 8), Match(10, 1, 6)], [Literals(0, "ab"), Literals(16, "!")]);

    //                     111111111122222222223333
    //           0123456789012345678901234567890123
    //           a
    //            aaaaaaaa
    //                    aaaaaaaa   
    //                            aaaaaaaa
    //                                    aaaaaaaa
    //                                            a          
    tester.test("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", [
        Match(1, 0, 8),
        Match(9, 0, 8),
        Match(17, 0, 8),
        Match(25, 0, 8)
        
    ], [
        Literals(0, "a"),
        Literals(33, "a"),
    ]);

    

    //                      1111111111222222222233
    //            01234567890123456789012345678901     
    //            one1two2
    //                    one (match:8, distance:7, length:3)
    //                       3
    //                        two (match:12, distance:7, length:3)
    //                           4
    //                            one (match:16, distance:7, length:3)
    //                               5
    //                                two (match:20, distance:7, length:3)
    //                                   6
    //                                    one (match:24, distance:7, length:3)
    //                                       7
    //                                        two (match:28, distance:7, length:3)
    //                                           8
    tester2.test("one1two2one3two4one5two6one7two8", [
        Match(8, 7, 3),
        Match(12, 7, 3),
        Match(16, 7, 3),
        Match(20, 7, 3),
        Match(24, 7, 3),
        Match(28, 7, 3)
    ], [
        Literals(0, "one1two2"),
        Literals(11, "3"),
        Literals(15, "4"),
        Literals(19, "5"),
        Literals(23, "6"),
        Literals(27, "7"),
        Literals(31, "8"),
    ]);
}
void wholeFileTests(LZ77Strategy STRATEGY)() {
    TestArgs args = {
        windowSize: 8, 
        maxMatchLength: 8, 
        maxLiteralsLength: 8,
    };

    auto tester = new Test!STRATEGY(args);

    tester.testFile("testdata/bib");
    tester.testFile("testdata/test1.txt");
    tester.testFile("testdata/test2.txt");
    tester.testFile("testdata/test3.txt");
    tester.testFile("testdata/geo");
    tester.testFile("testdata/book2");
    tester.testFile("testdata/bible.txt");
}

struct Match {
    ulong index;
    uint distance;
    uint length;
}
struct Literals {
    ulong index;
    string value;
}
struct TestArgs {
    uint windowSize;
    uint maxMatchLength;
    uint maxLiteralsLength;
}
final class Test(LZ77Strategy STRATEGY) {
public:    
    this(TestArgs args) {
        this.lz77 = new LZ77!STRATEGY(args.windowSize, args.maxMatchLength, args.maxLiteralsLength, &matchCallback, &literalsCallback);
    }
    void test(string source, Match[] expectedMatches, Literals[] expectedLiterals) {
        this.original = source.as!(ubyte[]);
        this.encoded.length = 0;
        this.actualMatches.length = 0;
        this.actualLiterals.length = 0;

        writefln("────────────────────────────────────────────────────────────");
        writefln("Testing '%s' (%s bytes)", source, source.length);

        lz77.encode(original);

        writefln("....");
        writefln("original (%s): '%s'", original.length, original.as!(char[]));
        writefln("encoded  (%s): '%s'", encoded.length,   encoded.as!(char[]));
        assert(encoded == original);
        assert(actualMatches == expectedMatches, "actualMatches = %s, expectedMatches = %s".format(actualMatches, expectedMatches));
        assert(actualLiterals == expectedLiterals, "actualLiterals = %s, expectedLiterals = %s".format(actualLiterals, expectedLiterals));
    }
    void testFile(string filename) {
        this.original = cast(ubyte[])read(filename);
        this.encoded.length = 0;
        this.actualMatches.length = 0;
        this.actualLiterals.length = 0;

        writefln("────────────────────────────────────────────────────────────");
        writefln("Testing file '%s' (%s bytes)", filename, original.length);

        lz77.encodeFile(filename);

        if(encoded.length != original.length) {
            writefln("Encoded length (%s) != original length (%s)", encoded.length, original.length);
        }
        if(encoded != original) {
            writefln("Encoded data != original data");
        }
        assert(encoded == original);
        writefln("Passed");
    }
private:
    LZ77!STRATEGY lz77;

    Match[] actualMatches;
    Literals[] actualLiterals;
    ubyte[] original;
    ubyte[] encoded;

    uint matchCallback(ulong index, uint distance, uint length) {
        //writefln("match: %s, %s, %s", index, distance, length);
        actualMatches ~= Match(index, distance, length);
        auto from = index - distance - 1;
        //writefln(" [%s] match: '%s'", index, original[from..from+length].as!(char[]));
        encoded ~= original[from..from+length];
        return length;
    }
    void literalsCallback(ulong index, ubyte[] literals) {
        actualLiterals ~= Literals(index, literals.as!(char[]));
        encoded ~= literals;
        //writefln(" [%s] literals: '%s'", index, literals.as!(char[]));
    }
}
