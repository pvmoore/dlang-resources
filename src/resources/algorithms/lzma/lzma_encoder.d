module resources.algorithms.lzma.lzma_encoder;

/**
 * https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Markov_chain_algorithm
 *
 *
 */
 import resources.all;

final class LZMAEncoder {
private:
    uint dictionarySize;
    ByteWriter outStream;
    ByteReader inStream;
public:
    this(ubyte[] bytes, ubyte[] props) {
        chat("decompressing %s bytes, props=%s", bytes.length, props);
        expect(props.length==5);
        applyProperties(props);

        this.inStream  = new ByteReader(bytes);
        this.outStream = new ArrayByteWriter();
    }

    ubyte[] decompress() {




        return null;
    }
private:
    void applyProperties(ubyte[] props) {
        auto val = props[0] & 0xff;
        auto rem = val / 9;
        auto lc  = val % 9; // 3  num literal context bits (0..8)
        auto lp  = rem % 5; // 0  literal pos bits (0..4)
        auto pb  = rem / 5; // 2  numPosStates = 1 << pb = 4 (0..4)

        chat("lc = %s, lp = %s, pb = %s", lc, lp, pb);

        foreach(i; 0..4) {
            dictionarySize += (cast(int)(props[1 + i]) & 0xff) << (i * 8);
        }
        chat("dictionarySize = %s", dictionarySize);
    }
}