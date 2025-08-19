module resources.models.gltf.meshopt.meshopt;

/** 
 * https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Vendor/EXT_meshopt_compression
 */
import resources.all;
private {
    import resources.models.gltf.gltf_common;
    import resources.models.gltf.meshopt.meshopt_attributes;    // Mode.ATTRIBUTES
    import resources.models.gltf.meshopt.meshopt_triangles;     // Mode.TRIANGLES
    import resources.models.gltf.meshopt.meshopt_indices;       // Mode.INDICES
    import resources.models.gltf.meshopt.meshopt_filter;        
}
/**
 * "EXT_meshopt_compression": {
 *    "buffer": 0,
 *    "byteOffset": 0,
 *    "byteLength": 11747,
 *    "byteStride": 8,
 *    "mode": "ATTRIBUTES",
 *    "count": 2887
 *  }
 */
void decodeMeshopt(GLTF gltf, BufferView view, string[string] props) {
    throwIf(!props.containsKey("buffer"), "buffer is required");
    throwIf(!props.containsKey("byteLength"), "byteLength is required");
    throwIf(!props.containsKey("byteStride"), "byteStride is required");
    throwIf(!props.containsKey("mode"), "mode is required");
    throwIf(!props.containsKey("count"), "count is required");

    enum Mode { ATTRIBUTES, TRIANGLES, INDICES }

    // Required properties
    uint srcBuffer  = props["buffer"].to!uint;
    uint byteLength = props["byteLength"].to!uint;
    uint byteStride = props["byteStride"].to!uint;
    uint count      = props["count"].to!uint;
    Mode mode       = props["mode"].to!Mode;

    // Optional properties
    uint byteOffset = props.get("byteOffset", "0").to!uint;
    Filter filter = props.get("filter", "NONE").to!Filter;

    ubyte[] encodedBytes = gltf.buffers[srcBuffer].data[byteOffset..byteOffset+byteLength];
    chat("decodeMeshopt %s bytes from buffer %s (%s..%s)", encodedBytes.length, srcBuffer, byteOffset, byteOffset+byteLength);

    ubyte[] decodedBytes = new ubyte[view.byteLength.get()];

    final switch(mode) {
        case Mode.ATTRIBUTES: new MeshoptAttributes().decode(encodedBytes, decodedBytes, byteStride, count); break;
        case Mode.TRIANGLES: new MeshoptTriangles().decode(encodedBytes, decodedBytes, byteStride, count); break;
        case Mode.INDICES: new MeshoptIndices().decode(encodedBytes, decodedBytes, byteStride, count); break;
    }

    applyDecodeFilter(filter, decodedBytes.ptr, count, byteStride);

    chat("decodedBytes length = %s", decodedBytes.length);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
package:

enum Filter { 
    NONE        = 0, 
    OCTAHEDRAL  = 1, // suitable for unit vectors as 4 pr 8 byte values with variable precision octahedral encoding
    QUATERNION  = 2, // suitable for rotation data for animations or instancing as 8 byte values 
    EXPONENTIAL = 3  // suitable for floating point data as 4 byte values with variable mantissa precision
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/+
ubyte readByte(ubyte[] bytes, ref uint index) {
    return bytes[index++];
}
uint decodeLEB128(ubyte[] bytes, ref uint index) {
    ubyte lead = readByte(bytes, index);

    if(lead < 128) return lead;

    uint result = lead & 127;
    uint shift  = 7;

    foreach(i; 0..4) { 
        uint group = readByte(bytes, index);
        result |= (group & 127) << shift;
        shift += 7;

        if(group < 128) break;
    }
    return result;
}

/**
 * Mode 1: triangles. Suitable for storing indices that represent triangle lists, relies on 
 * exploiting topological redundancy of consecutive triangles.
 *
 * Conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/indexcodec.cpp -> meshopt_decodeIndexBuffer
 */
ubyte[] decodeTriangles(ubyte[] encodedBytes, Filter filter, uint byteStride, uint indexCount) {
    chat("decodeTriangles");

    throwIf(indexCount % 3 != 0, "Index count must be a multiple of 3");
    throwIf(!byteStride.isOneOf(2,4), "Triangle byteStride must be 2 or 4");

    enum HEADER_MAJOR   = 0xe0;
    enum HEADER_VERSION = 1;

    uint srcIndex;
    auto header        = readByte(encodedBytes, srcIndex);
    auto headerMajor   = header & 0xf0;
    auto headerVersion = header & 0x0f;
    throwIf(headerMajor   != HEADER_MAJOR, "Invalid meshopt TRIANGLES header byte");
    throwIf(headerVersion != HEADER_VERSION, "Expecting version %s header byte", HEADER_VERSION);

    static struct Edge { uint a; uint b; }

    uint next = 0;
    uint last = 0;
    Edge[16] edgeFifo;  
    uint[16] vertexFifo; 
    edgeFifo[] = Edge(-1,-1);
    vertexFifo[] = -1;
    uint edgeFifoIndex = 0;
    uint vertexFifoIndex = 0;
    ubyte[16] codeauxTable = encodedBytes[$-16..$];

    enum fecmax = 13;

    ArrayByteWriter writer = new ArrayByteWriter();

    uint decodeIndex() {
        uint v = decodeLEB128(encodedBytes, srcIndex);
        uint d = (v >> 1) ^ -cast(int)(v & 1);
	    return last + d;
    }
    void pushVertex(uint v, uint inc = 1) {
        vertexFifo[vertexFifoIndex] = v;
        vertexFifoIndex = (vertexFifoIndex + inc) & 15;
    }
    void pushEdge(uint a, uint b) {
        edgeFifo[edgeFifoIndex] = Edge(a, b);
        edgeFifoIndex = (edgeFifoIndex + 1) & 15;
    }
    void writeTriangle(uint a, uint b, uint c) {
        if(byteStride == 2) {
            writer.write!ushort(a.as!ushort);
            writer.write!ushort(b.as!ushort);
            writer.write!ushort(c.as!ushort);
        } else {
            writer.write!uint(a);
            writer.write!uint(b);
            writer.write!uint(c);
        }
    } 

    // Per triangle
    foreach(i; 0..indexCount/3) {

        ubyte codetri = readByte(encodedBytes, srcIndex);

        // 0xX0, where X < 0xf: Encodes a recently encountered edge and a next vertex
        if(codetri < 0xf0) {
            uint fe = codetri >> 4;
            uint a = edgeFifo[(edgeFifoIndex-1-fe) & 15].a;
            uint b = edgeFifo[(edgeFifoIndex-1-fe) & 15].b;
            uint c;

            uint fec = codetri & 15;

            if(fec < fecmax) {
                uint cf = vertexFifo[(vertexFifoIndex-1-fec) & 15];
                c = (fec == 0) ? next : cf;

                uint fec0 = (fec == 0) ? 1 : 0;
                next += fec0;

                pushVertex(c, fec0);
            } else {
                last = c = (fec != 15) ? last + (fec - (fec^3)) : decodeIndex();

                pushVertex(c);
            }

            pushEdge(c, b);
            pushEdge(a, c);

            writeTriangle(a, b, c);

        // 0xXY, where X < 0xf and 0 < Y < 0xd: Encodes a recently encountered edge and a recently encountered vertex
        } else {
            if(codetri < 0xfe) {
                ubyte codeaux = codeauxTable[codetri & 15];

                uint feb = codeaux >> 4;
                uint fec = codeaux & 15;

                uint a = next++;
                uint bf = vertexFifo[(vertexFifoIndex - feb) & 15];
                uint b = (feb == 0) ? next : bf;

                uint feb0 = (feb == 0) ? 1 : 0;
                next += feb0;

                uint cf = vertexFifo[(vertexFifoIndex - fec) & 15];
                uint c = (fec == 0) ? next : cf;

                uint fec0 = (fec == 0) ? 1 : 0;
                next += fec0;

                writeTriangle(a, b, c);

                pushVertex(a);
                pushVertex(b, feb0);
                pushVertex(c, fec0);

                pushEdge(b, a);
                pushEdge(c, b);
                pushEdge(a, c);
            } else {
                ubyte codeaux = readByte(encodedBytes, srcIndex);

                uint fea = codetri == 0xfe ? 0 : 15;
                uint feb = codeaux >> 4;
                uint fec = codeaux & 15;

                if(codeaux == 0) next = 0;

                uint a = (fea == 0) ? next++ : 0;
                uint b = (feb == 0) ? next++ : vertexFifo[(vertexFifoIndex - feb) & 15];
                uint c = (fec == 0) ? next++ : vertexFifo[(vertexFifoIndex - fec) & 15];

                if(fea == 15) last = a = decodeIndex();
                if(feb == 15) last = b = decodeIndex();
                if(fec == 15) last = c = decodeIndex();

                writeTriangle(a, b, c);

                pushVertex(a);
                pushVertex(b, (feb == 0) | (feb == 15));
                pushVertex(c, (fec == 0) | (fec == 15));

                pushEdge(b, a);
                pushEdge(c, b);
                pushEdge(a, c);
            }
        }
    }

    if(filter != Filter.NONE) todo("decodeTriangles: support filter %s".format(filter));
    return writer.getArray();
}

/**
 * Mode 2: indices. Suitable for storing indices that don't represent triangle lists, relies 
 * on exploiting similarity between consecutive elements.
 *
 * Conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/indexcodec.cpp -> meshopt_decodeIndexSequence 
 */
ubyte[] decodeIndices(ubyte[] encodedBytes, Filter filter, uint byteStride, uint indexCount) {
    chat("decodeIndices");

    throwIf(!byteStride.isOneOf(2,4), "Index byteStride must be 2 or 4");

    enum HEADER_MAJOR   = 0xd0;
    enum HEADER_VERSION = 1;

    ArrayByteWriter writer = new ArrayByteWriter();
    uint srcIndex;
    auto header        = readByte(encodedBytes, srcIndex);
    auto headerMajor   = header & 0xf0;
    auto headerVersion = header & 0x0f;
    throwIf(headerMajor   != HEADER_MAJOR, "Invalid meshopt INDICES header byte");
    throwIf(headerVersion != HEADER_VERSION, "Expecting version %s header byte", HEADER_VERSION);

    uint[2] last;

    // Per index
    foreach(i; 0..indexCount) {
        uint v = decodeLEB128(encodedBytes, srcIndex);
        uint current = (v & 1);
        v >>= 1;

        uint d = (v >> 1) ^ -cast(int)(v & 1);
        uint index = last[current] + d;

        last[current] = index;

        if(byteStride == 2) {
            writer.write!ushort(index.as!ushort);
        } else {
            writer.write!uint(index);
        }
    }

    if(filter != Filter.NONE) todo("decodeIndices: support filter %s".format(filter));

    return writer.getArray();
}

+/
