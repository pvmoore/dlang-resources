module resources.data.bzip.BZip3;

private import std.string   : fromStringz;
private import common.utils : as, throwIf;
private import maths        : minOf, maxOf;
private import resources.data.bzip.bzip3_api;

// Link in bzip3.lib
pragma(lib, "bzip3");

/**
 *  https://github.com/iczelia/bzip3
 *
 *  Todo:
 *    - This can be improved by processing the chunks in parallel
 */
final class BZip3 { 
public:
    static string versionString() {
        return bz3_version().fromStringz().as!string;
    }
    /**
     * Compress data into a stream of one or more blocks. 
     * 
     * params:
     *  - input     = data to compress
     *  - blockSize = block size in MiB (min 1, max 511)
     *
     * The stream starts with a 9 byte header:
     *  - 5 bytes = magic number "BZ3v1"
     *  - 4 bytes = block size LE
     *
     * Each compressed block starts with an 8 byte header:
     *  - 4 bytes = block compressed size LE
     *  - 4 bytes = block original size LE
     *  - compressed data
     */
    static ubyte[] compress(ubyte[] input, uint blockSize) {
        blockSize = MiB(blockSize);
        blockSize = maxOf(minOf(blockSize, MAXIMUM_BLOCK_SIZE), MINIMUM_BLOCK_SIZE);

        bz3_state* state = bz3_new(blockSize.as!uint);
        throwIf(state is null, "BZIP3: Compression failed");
        scope(exit) bz3_free(state);

        ulong bufferSize = bz3_bound(blockSize);

        ubyte[] compressed;
        ubyte[] buffer = new ubyte[bufferSize];
        ulong bytesRead;

        // Write the magic number
        compressed ~= MAGIC;

        // Write the blockSize
        compressed ~= to4Bytes(blockSize);

        while(true) {
            int inSize = readFromInput(input, buffer, blockSize, bytesRead);
            if(inSize == 0) break;

            int outSize = bz3_encode_block(state, buffer.ptr, inSize);
            throwIf(outSize < 0, "BZIP3: Compression failed");

            // Write compressed size, original size, compressed block data
            compressed ~= to4Bytes(outSize);
            compressed ~= to4Bytes(inSize);
            compressed ~= buffer[0..outSize];
        }

        return compressed;
    }
    /**
     * Decompress a stream of one or more blocks.
     *
     * The stream is assumed to start with a 9 byte header:
     *  - 5 bytes = magic number "BZ3v1"
     *  - 4 bytes = block size LE
     * 
     * Each compressed block is assumed to start with an 8 byte header:
     *  - 4 bytes = block compressed size LE
     *  - 4 bytes = block original size LE
     *  - compressed data
     */
    static ubyte[] decompress(ubyte[] input) {

        throwIf(input.length < 9, "BZip3: Input is expected to be at least 9 bytes");
        throwIf(input[0..5] != MAGIC, "BZip3: This is not a valid stream");

        uint blockSize = from4Bytes(input[5..9]);
        throwIf(blockSize < MINIMUM_BLOCK_SIZE || blockSize > MAXIMUM_BLOCK_SIZE, "BZip3: Invalid block size: %s", blockSize);

        bz3_state* state = bz3_new(blockSize.as!uint);
        throwIf(state is null, "BZIP3: Decompression failed");
        scope(exit) bz3_free(state);

        ulong bufferSize = bz3_bound(blockSize);

        ubyte[] buffer = new ubyte[bufferSize];
        ubyte[] compressed;

        ulong bytesRead = 9;

        while(bytesRead < input.length) {
            int compressedSize = from4Bytes(input[bytesRead..bytesRead+4]);
            bytesRead += 4;
            int originalSize = from4Bytes(input[bytesRead..bytesRead+4]);
            bytesRead += 4;

            int readSize = readFromInput(input, buffer, compressedSize, bytesRead);
            throwIf(readSize != compressedSize, "BZIP3: Decompression failed");

            int outSize2 = bz3_decode_block(state, buffer.ptr, bufferSize, compressedSize, originalSize);
            throwIf(outSize2 != originalSize, "BZIP3: Decompression failed");

            compressed ~= buffer[0..originalSize];
        }

        return compressed;
    }
private:
    enum MINIMUM_BLOCK_SIZE = KiB(55);  
    enum MAXIMUM_BLOCK_SIZE = MiB(511);
    enum MAGIC              = "BZ3v1";

    static uint KiB(uint kib) {
        return kib * 1024;
    }
    static uint MiB(uint mib) {
        return mib * 1024*1024;
    }
    static ubyte[4] to4Bytes(int i) {
        return [(i & 0xff).as!ubyte, ((i>>8) & 0xff).as!ubyte, ((i>>16) & 0xff).as!ubyte, ((i>>24) & 0xff).as!ubyte];
    }
    static int from4Bytes(ubyte[] bytes) {
        return bytes[0] | (bytes[1]<<8) | (bytes[2]<<16) | (bytes[3]<<24);
    }
    static int readFromInput(ubyte[] input, ubyte[] buffer, uint numBytes, ref ulong bytesRead) {
        // Read blockSize bytes into the buffer
        ulong remaining  = input.length - bytesRead;
        int readNumBytes = minOf(numBytes, remaining).as!int; 

        buffer[0..readNumBytes] = input[bytesRead..bytesRead+readNumBytes];
        bytesRead += readNumBytes;

        return readNumBytes;
    }
}
