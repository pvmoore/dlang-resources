module resources.models.gltf.meshopt.meshopt_triangles;

/**
 * Mode 1: TRIANGLES. Suitable for storing indices that represent triangle lists, relies on 
 * exploiting topological redundancy of consecutive triangles.
 *
 * D conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/indexcodec.cpp 
 */

import resources.all;

private {
    import core.stdc.string : memset;
}

final class MeshoptTriangles {
public:
    void decode(ubyte[] inputBytes, ubyte[] outputBytes, uint byteStride, uint indexCount) {
        throwIf(indexCount % 3 != 0, "Index count must be a multiple of 3");
        throwIf(!byteStride.isOneOf(2,4), "Triangle byteStride must be 2 or 4");

        throwIf(0 != meshopt_decodeIndexBuffer(outputBytes.ptr, indexCount, byteStride, inputBytes.ptr, inputBytes.length));
    }
private:
    enum HEADER_MAJOR             = 0xe0;
    enum HEADER_SUPPORTED_VERSION = 1;

    static struct Edge { uint a; uint b; }

    uint[16] vertexfifo;
    Edge[16] edgefifo;

    void pushVertexFifo(uint v, ref size_t offset, int cond = 1) {
        vertexfifo[offset] = v;
        offset = (offset + cond) & 15;
    }
    void pushEdgeFifo(uint a, uint b, ref size_t offset) {
        edgefifo[offset].a = a;
        edgefifo[offset].b = b;
        offset = (offset + 1) & 15;
    }
    uint decodeVByte(ref const(ubyte)* data) {
        ubyte lead = *data++;

        // fast path: single byte
        if(lead < 128)
            return lead;

        // slow path: up to 4 extra bytes
        // note that this loop always terminates, which is important for malformed data
        uint result = lead & 127;
        uint shift = 7;

        for(int i = 0; i < 4; ++i) {
            ubyte group = *data++;
            result |= cast(uint)(group & 127) << shift;
            shift += 7;

            if(group < 128)
                break;
        }

        return result;
    }

    void writeTriangle(void* destination, size_t offset, size_t index_size, uint a, uint b, uint c) {
        if(index_size == 2) {
            destination.as!(ushort*)[offset + 0] = a.as!ushort;
            destination.as!(ushort*)[offset + 1] = b.as!ushort;
            destination.as!(ushort*)[offset + 2] = c.as!ushort;
        } else {
            destination.as!(uint*)[offset + 0] = a;
            destination.as!(uint*)[offset + 1] = b;
            destination.as!(uint*)[offset + 2] = c;
        }
    }

    uint decodeIndex(ref const(ubyte)* data, uint last) {
        uint v = decodeVByte(data);
        uint d = (v >> 1) ^ -cast(int)(v & 1);
        return last + d;
    }
    
    int meshopt_decodeIndexBuffer(void* destination, size_t index_count, size_t index_size, const(ubyte)* buffer, size_t buffer_size)
    {
        // the minimum valid encoding is header, 1 byte per triangle and a 16-byte codeaux table
        if(buffer_size < 1 + index_count / 3 + 16)
            return -2;

        if((buffer[0] & 0xf0) != HEADER_MAJOR)
            return -1;

        int version_ = buffer[0] & 0x0f;
        if(version_ > HEADER_SUPPORTED_VERSION)
            return -1;

        memset(edgefifo.ptr, -1, edgefifo.sizeof);
        memset(vertexfifo.ptr, -1, vertexfifo.sizeof);

        size_t edgefifooffset = 0;
        size_t vertexfifooffset = 0;

        uint next = 0;
        uint last = 0;

        int fecmax = version_ >= 1 ? 13 : 15;

        // since we store 16-byte codeaux table at the end, triangle data has to begin before data_safe_end
        const(ubyte)* code = buffer + 1;
        const(ubyte)* data = code + index_count / 3;
        const(ubyte)* data_safe_end = buffer + buffer_size - 16;

        const(ubyte)* codeaux_table = data_safe_end;

        for(size_t i = 0; i < index_count; i += 3) {
            // make sure we have enough data to read for a triangle
            // each triangle reads at most 16 bytes of data: 1b for codeaux and 5b for each free index
            // after this we can be sure we can read without extra bounds checks
            if (data > data_safe_end)
                return -2;

            ubyte codetri = *code++;

            if(codetri < 0xf0) {
                int fe = codetri >> 4;

                // fifo reads are wrapped around 16 entry buffer
                uint a = edgefifo[(edgefifooffset - 1 - fe) & 15].a;
                uint b = edgefifo[(edgefifooffset - 1 - fe) & 15].b;
                uint c = 0;

                int fec = codetri & 15;

                // note: this is the most common path in the entire decoder
                // inside this if we try to stay branchless (by using cmov/etc.) since these aren't predictable
                if(fec < fecmax) {
                    // fifo reads are wrapped around 16 entry buffer
                    uint cf = vertexfifo[(vertexfifooffset - 1 - fec) & 15];
                    c = (fec == 0) ? next : cf;

                    int fec0 = fec == 0;
                    next += fec0;

                    // push vertex fifo must match the encoding step *exactly* otherwise the data will not be decoded correctly
                    pushVertexFifo(c, vertexfifooffset, fec0);
                }
                else
                {
                    // fec - (fec ^ 3) decodes 13, 14 into -1, 1
                    // note that we need to update the last index since free indices are delta-encoded
                    last = c = (fec != 15) ? last + (fec - (fec ^ 3)) : decodeIndex(data, last);

                    // push vertex/edge fifo must match the encoding step *exactly* otherwise the data will not be decoded correctly
                    pushVertexFifo(c, vertexfifooffset);
                }

                // push edge fifo must match the encoding step *exactly* otherwise the data will not be decoded correctly
                pushEdgeFifo(c, b, edgefifooffset);
                pushEdgeFifo(a, c, edgefifooffset);

                // output triangle
                writeTriangle(destination, i, index_size, a, b, c);
            }
            else
            {
                // fast path: read codeaux from the table
                if (codetri < 0xfe)
                {
                    ubyte codeaux = codeaux_table[codetri & 15];

                    // note: table can't contain feb/fec=15
                    int feb = codeaux >> 4;
                    int fec = codeaux & 15;

                    // fifo reads are wrapped around 16 entry buffer
                    // also note that we increment next for all three vertices before decoding indices - this matches encoder behavior
                    uint a = next++;

                    uint bf = vertexfifo[(vertexfifooffset - feb) & 15];
                    uint b = (feb == 0) ? next : bf;

                    int feb0 = feb == 0;
                    next += feb0;

                    uint cf = vertexfifo[(vertexfifooffset - fec) & 15];
                    uint c = (fec == 0) ? next : cf;

                    int fec0 = fec == 0;
                    next += fec0;

                    // output triangle
                    writeTriangle(destination, i, index_size, a, b, c);

                    // push vertex/edge fifo must match the encoding step *exactly* otherwise the data will not be decoded correctly
                    pushVertexFifo(a, vertexfifooffset);
                    pushVertexFifo(b, vertexfifooffset, feb0);
                    pushVertexFifo(c, vertexfifooffset, fec0);

                    pushEdgeFifo(b, a, edgefifooffset);
                    pushEdgeFifo(c, b, edgefifooffset);
                    pushEdgeFifo(a, c, edgefifooffset);
                }
                else
                {
                    // slow path: read a full byte for codeaux instead of using a table lookup
                    ubyte codeaux = *data++;

                    int fea = codetri == 0xfe ? 0 : 15;
                    int feb = codeaux >> 4;
                    int fec = codeaux & 15;

                    // reset: codeaux is 0 but encoded as not-a-table
                    if (codeaux == 0)
                        next = 0;

                    // fifo reads are wrapped around 16 entry buffer
                    // also note that we increment next for all three vertices before decoding indices - this matches encoder behavior
                    uint a = (fea == 0) ? next++ : 0;
                    uint b = (feb == 0) ? next++ : vertexfifo[(vertexfifooffset - feb) & 15];
                    uint c = (fec == 0) ? next++ : vertexfifo[(vertexfifooffset - fec) & 15];

                    // note that we need to update the last index since free indices are delta-encoded
                    if (fea == 15)
                        last = a = decodeIndex(data, last);

                    if (feb == 15)
                        last = b = decodeIndex(data, last);

                    if (fec == 15)
                        last = c = decodeIndex(data, last);

                    // output triangle
                    writeTriangle(destination, i, index_size, a, b, c);

                    // push vertex/edge fifo must match the encoding step *exactly* otherwise the data will not be decoded correctly
                    pushVertexFifo(a, vertexfifooffset);
                    pushVertexFifo(b, vertexfifooffset, (feb == 0) | (feb == 15));
                    pushVertexFifo(c, vertexfifooffset, (fec == 0) | (fec == 15));

                    pushEdgeFifo(b, a, edgefifooffset);
                    pushEdgeFifo(c, b, edgefifooffset);
                    pushEdgeFifo(a, c, edgefifooffset);
                }
            }
        }

        // we should've read all data bytes and stopped at the boundary between data and codeaux table
        if (data != data_safe_end)
            return -3;

        return 0;
    }
}
