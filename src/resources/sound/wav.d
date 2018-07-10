module resources.sound.wav;
/**
 * http://soundfile.sapp.org/doc/WaveFormat/
 * https://web.archive.org/web/20141213140451/https://ccrma.stanford.edu/courses/422/projects/WaveFormat/
 */
import resources.all;

final class WavFile {
private:
    RIFFHeader riff;
    FormatSubChunk fmt;
    DataSubChunk data;
public:
    byte[] bytes;

    uint frequency()     { return fmt.sampleRate; }
    ulong lengthMillis() { return (bytes.length*1000) / fmt.byteRate; }
    int numChannels()    { return fmt.numChannels; }
    int bitsPerSample()  { return fmt.bitsPerSample; }

    this(string filename) {
        log("Loading wav file: '%s'", filename);
        scope file = File(filename, "rb");

        //---------------------------------------------
        // riff header
        //---------------------------------------------
        riff = file.rawRead(new RIFFHeader[1])[0];

        if(riff.riff != ['R','I','F','F'] ||
        riff.fmt  != ['W','A','V','E'])
        {
            throw new Exception("Bad WAV file format");
        }
        log("chunkSize=%s", riff.chunkSize);

        //---------------------------------------------
        // fmt subchunk
        //---------------------------------------------
        fmt  = file.rawRead(new FormatSubChunk[1])[0];

        log("formatChunkHeader=%s", fmt.formatChunkHeader);
        log("formatChunkSize=%s", fmt.formatChunkSize);
        log("audioFormat=%s", fmt.audioFormat);
        log("numChannels=%s", fmt.numChannels);
        log("sampleRate=%s", fmt.sampleRate);
        log("bitsPerSample=%s", fmt.bitsPerSample);
        log("byteRate=%s", fmt.byteRate);

        if(fmt.audioFormat!=1) {
            throw new Exception("Unsupported WAV format: %s".format(fmt.audioFormat));
        }

        // Note that it is possible that there is
        // a ushort ExtraParamSize here even if the
        // audioFormat==1 which should not happen :|
        char[2] extraParamSize = file.rawRead(new char[2]);
        if(extraParamSize == ['d','a']) {
            // rewind 2 bytes
            file.seek(-2, SEEK_CUR);
        } else {
            log("skipping extraParamSize which should not be here");
        }

        //---------------------------------------------
        // data subchunk
        //---------------------------------------------
        data = file.rawRead(new DataSubChunk[1])[0];

        log("dataChunkHeader=%s", cast(char[4])data.chunkHeader);
        log("dataChunkSize=%s", data.chunkSize);

        if(fmt.bitsPerSample==8) {
            // unsigned bytes (0 to 255)
            bytes = file.rawRead(new byte[data.chunkSize]);
        } else if(fmt.bitsPerSample==16) {
            // signed shorts (-32768 to 32767)
            bytes = cast(byte[])file.rawRead(new short[data.chunkSize/2]);
        } else {
            throw new Exception("Unsupported WAV bitsPerSample=%s".format(fmt.bitsPerSample));
        }

        log("bytes.length=%s", bytes.length);
    }
}
private:

align(1) struct RIFFHeader { align(1):
    ubyte[4] riff;      // "RIFF"
    uint chunkSize;
    ubyte[4] fmt;       // "WAVE"
}
static assert(RIFFHeader.sizeof==12);

align(1) struct ListSubChunk { align(1):
    // todo
}
align(1) struct FactSubChunk { align(1):
    // todo
}
align(1) struct InfoSubChunk { align(1):
    // todo
}

align(1) struct FormatSubChunk { align(1):
    char[4] formatChunkHeader;   // "fmt "
    uint formatChunkSize;
    ushort audioFormat;     // 1 = PCM
    ushort numChannels;     // 1 = mono, 2 = stereo
    uint sampleRate;        // eg. 44000
    uint byteRate;          // (Sample Rate * BitsPerSample * Channels) / 8
    ushort blockAlign;      // (BitsPerSample * Channels) / 8.1 - 8 bit mono2 - 8 bit stereo/16 bit mono4 - 16 bit stereo
    ushort bitsPerSample;
}
static assert(FormatSubChunk.sizeof==24);

align(1) struct DataSubChunk { align(1):
    ubyte[4] chunkHeader;   // "data"
    uint chunkSize;
}
static assert(DataSubChunk.sizeof==8);

