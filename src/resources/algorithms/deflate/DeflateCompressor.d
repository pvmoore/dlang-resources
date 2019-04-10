module resources.algorithms.deflate.DeflateCompressor;

import resources.algorithms.deflate;
import resources.all;

final class DeflateCompressor {
private:

public:
    ubyte[] compress(string filename) {
        auto buf = appender!(ubyte[]);
        auto writer = new BitWriter(it=>buf ~= it);
        auto reader = new FileByteReader(filename);

        compressStream(reader, writer);

        return buf.data;
    }
    ubyte[] compress(ubyte[] stream) {
        auto buf = appender!(ubyte[]);
        auto writer = new BitWriter(it=>buf ~= it);
        auto reader = new ByteReader(stream);

        compressStream(reader, writer);

        return buf.data;
    }
private:
    ByteReader reader; 
    BitWriter writer;

    void compressStream(ByteReader reader, BitWriter writer) {
        this.reader = reader;
        this.writer = writer;

    }
    void compressLiteralBlock(ushort length, bool isLast = false) {
        chat("literal block");

        // 3-bit header
        writer.write(isLast ? 1 : 0, 1);
        writer.write(0b00, 2);

        // max block length = 64k

        // skip any remaining bits in current partially processed byte
        writer.flush();

        // write LEN
        writer.write(length, 16);

        // write NLEN
        writer.write(~cast(uint)length, 16);

        // copy LEN bytes of data to output
        for(auto i=0; i<length; i++) {
            writer.write(reader.read!ubyte, 8);
        }
    }
    void compressBlock(bool isLast = false) {
        chat("compress block");
        // 3-bit header
        writer.write(isLast ? 1 : 0, 1);
        writer.write(0b10, 2);  // huffman tree supplied

        // unlimited length block, 32k window size

        // match length = 3 to 258 bytes   (8 bits)
        // distance     = 1 to 32768 bytes (15 bits)

        // huffman tree 1 = literals and lengths
        // huffman tree 2 = distances

        // todo - huffman tree data

        // todo - write bytes
    }
}