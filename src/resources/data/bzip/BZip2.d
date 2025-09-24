module resources.data.bzip.BZip2;

private import std.string   : fromStringz;
private import common.utils : as, throwIf;
private import resources.data.bzip.bzip2_api;

// Link in bzip2.lib
pragma(lib, "bzip2");

/**
 *  https://en.wikipedia.org/wiki/Bzip2
 */
final class BZip2 { 
public:
    static string versionString() {
        return BZ2_bzlibVersion().fromStringz().as!string;
    }
    static ubyte[] compress(ubyte[] data, uint bufferSize = BUF_SIZE) {
        ubyte[] compressed;
        ubyte[] outputBuffer = new ubyte[bufferSize];

        bz_stream strm;
        int bzerror = BZ2_bzCompressInit(&strm, 9, 0, 0);
        throwIf(bzerror != BZ_OK, "BZIP2 compression failed: %s", bzerror); 

        ulong bytesRead;
        ulong bytesWritten;

        // Repeat until all of the input data is consumed
        while(bytesRead < data.length) {
            ulong dataAvailable = data.length-bytesRead; 
            if(dataAvailable > bufferSize) dataAvailable = bufferSize;

            strm.next_in  = (data.ptr + bytesRead).as!(char*);
            strm.avail_in = dataAvailable.as!uint; 

            strm.next_out  = outputBuffer.ptr.as!(char*);
            strm.avail_out = outputBuffer.length.as!uint;

            bzerror = BZ2_bzCompress(&strm, BZ_RUN);
            throwIf(bzerror != BZ_RUN_OK, "BZIP2 compression failed: %s", bzerror); 

            ulong prevBytesWritten = bytesWritten; 
            bytesRead    = getBytesRead(&strm);
            bytesWritten = getBytesWritten(&strm);

            ulong numBytesOut = bytesWritten - prevBytesWritten;
            if(numBytesOut > 0) {
                compressed ~= outputBuffer[0..numBytesOut];
            }
        }

        bzerror = BZ_OK;

        // Repeat until all of the output data is written
        while(bzerror != BZ_STREAM_END) {
            strm.next_out  = outputBuffer.ptr.as!(char*);
            strm.avail_out = outputBuffer.length.as!uint;

            bzerror = BZ2_bzCompress(&strm, BZ_FINISH);
            throwIf(bzerror != BZ_FINISH_OK && bzerror != BZ_STREAM_END, "BZIP2 compression failed: %s", bzerror); 

            ulong prevBytesWritten = bytesWritten;
            bytesWritten = getBytesWritten(&strm);
            ulong numBytesOut = bytesWritten - prevBytesWritten;

            compressed ~= outputBuffer[0..numBytesOut];
        }

        bzerror = BZ2_bzCompressEnd(&strm);
        throwIf(bzerror != BZ_OK, "BZIP2 compression failed: %s", bzerror); 

        return compressed;
    }
    static ubyte[] decompress(ubyte[] data, uint bufferSize = BUF_SIZE) {
        ubyte[] decompressed;
        ubyte[] outputBuffer = new ubyte[bufferSize];

        bz_stream strm;
        int bzerror = BZ2_bzDecompressInit(&strm, 0, 0);    
        throwIf(bzerror != BZ_OK, "BZIP2 decompression failed: %s", bzerror); 

        while(bzerror != BZ_STREAM_END) {
            ulong bytesRead     = getBytesRead(&strm);
            ulong bytesWritten  = getBytesWritten(&strm);

            ulong dataAvailable = data.length-bytesRead; 
            if(dataAvailable > bufferSize) dataAvailable = bufferSize;

            strm.next_in  = (data.ptr + bytesRead).as!(char*);
            strm.avail_in = dataAvailable.as!uint;

            strm.next_out  = outputBuffer.ptr.as!(char*);
            strm.avail_out = outputBuffer.length.as!uint;

            bzerror = BZ2_bzDecompress(&strm);
            throwIf(bzerror != BZ_OK && bzerror != BZ_STREAM_END, "BZIP2 decompression failed: %s", bzerror); 

            ulong numBytesOut = getBytesWritten(&strm) - bytesWritten;
            if(numBytesOut > 0) {
                decompressed ~= outputBuffer[0..numBytesOut];
            }
        }

        bzerror = BZ2_bzDecompressEnd(&strm);
        throwIf(bzerror != BZ_OK, "BZIP2 decompression failed: %s", bzerror); 

        return decompressed;
    }
private:
    enum BUF_SIZE = 64*1024;
    static ulong getBytesRead(bz_stream* strm) { return (strm.total_in_hi32.as!ulong << 32) + strm.total_in_lo32; }
    static ulong getBytesWritten(bz_stream* strm) { return (strm.total_out_hi32.as!ulong << 32) + strm.total_out_lo32; }
}
