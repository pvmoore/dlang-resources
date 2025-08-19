module resources.models.gltf.glb_reader;

/**
 * https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#glb-file-format-specification-structure
 */
import resources.all;
private {
    import resources.models.gltf.gltf_common;
    import resources.models.gltf.gltf_reader;

    enum MAGIC = 0x46546C67;
}

struct Header { static assert(Header.sizeof == 12);
    uint magic;
    uint version_;
    uint length;

    string toString() {
        return "Header(magic: 0x%8x, version: %s, length: %s)".format(magic, version_, length);
    }
}
enum ChunkType : uint {
    JSON = 0x4E4F534A,
    BIN  = 0x004E4942
}
struct Chunk {
    uint chunkLength;
    ChunkType chunkType;
    ubyte[] chunkData;

    string toString() {
        return "Chunk(length: %s, type: %s)".format(chunkLength, chunkType);
    }
}

void readBinaryGLTF(GLTF gltf) {
    chat("Reading GLTF binary file '%s'", gltf.filename);

    auto reader = new FileByteReader(gltf.filename);
    scope(exit) reader.close();

    Header header = readHeader(reader);
    chat("%s", header);

    // Read Chunks 
    // The first chunk is always JSON and is mandatory
    // If present, the BIN chunk should be second
    // Subsequent chunks are optional
    Chunk[] chunks;
    while(!reader.eof()) {
        chunks ~= readChunk(reader);
    }
    chat("Read %s chunks", chunks.length);
    throwIf(chunks.length < 1, "At least one chunk is expected");

    string jsonString = chunks[0].chunkData.as!string;

    static if(true) {
        import std.file : write;
        import std.string : replace;
        string str = jsonString;
        str = str.replace("{\"", "{\n    \"");
        str = str.replace(",\"", ",\n    \"");
        str = str.replace(",{", ",\n    {");
        str = str.replace("},", "\n},");
        write("temp.json", str);
    }

    if(chunks.length > 1 && chunks[1].chunkType == ChunkType.BIN) {
        gltf.binaryChunkData = chunks[1].chunkData;
    }
    // Read the json
    readJsonGLTF(gltf, jsonString);
}
Header readHeader(ByteReader reader) {
    Header header;
    header.magic = reader.read!uint;
    throwIf(header.magic != MAGIC, "Invalid magic number");

    header.version_ = reader.read!uint;
    throwIf(header.version_ != 2, "Only glTF 2.0 is supported");

    header.length = reader.read!uint;
    return header;
}
Chunk readChunk(ByteReader reader) {
    Chunk chunk;
    chunk.chunkLength = reader.read!uint;
    chunk.chunkType   = reader.read!uint.as!ChunkType;
    chunk.chunkData   = reader.readArray!ubyte(chunk.chunkLength);
    chat("%s", chunk);
    return chunk;
}
