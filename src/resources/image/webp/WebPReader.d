module resources.image.webp.WebPReader;

import resources.all;
import resources.image.webp;
import resources.image.webp.VP8L;

import std.stdio : writefln;

final class WebPReader {
public:
    WebP read(string filename) {
        this.reader = new FileByteReader(filename);

        readHeader();

        auto fourCC = reader.readArray!ubyte(4).as!string;
        writefln("[%s]", fourCC);

        switch(fourCC) {
            case "VP8 ": readVP8Chunk(); break;
            case "VP8L": readVP8LChunk(); break;
            case "VP8X": readVP8XChunk(); break;
            default: 
                throwIf(true, "Unhandled fourCC %s", fourCC);
                break;
        }

        return null;
    }
private:
    ByteReader reader;

    void readHeader() {
        auto riff = reader.readArray!ubyte(4).as!string;
        throwIf(riff != "RIFF", "Not a valid WebP file");
        uint fileSize = reader.read!uint;
        auto webp = reader.readArray!ubyte(4).as!string;
        throwIf(webp != "WEBP", "Not a valid WebP file");
        writefln("fileSize = %s", fileSize);
    }
    /**
     * Lossy VP8 chunk
     */
    void readVP8Chunk() {
        throwIf(true, "VP8 (Lossy) is not supported yet");
    }
    /**
     * Lossless VP8L chunk
     */
    void readVP8LChunk() {
        uint chunkSize = reader.read!uint;
        ubyte signature = reader.read!ubyte;
        throwIf(signature != 0x2f, "Invalid VP8L signature");
        writefln("%s", chunkSize);

        auto bits = reader.getBitReader();
        
        auto vp8l = new VP8L;
        vp8l.decode(bits);

    }
    /**
     * Extended file format VP8X chunk
     */
    void readVP8XChunk() {
        throwIf(true, "VP8X (Extended) is not supported yet");
    }
}
