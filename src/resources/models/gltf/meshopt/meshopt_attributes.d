module resources.models.gltf.meshopt.meshopt_attributes;

/**
 * Mode 0: ATTRIBUTES. Suitable for storing sequences of values of arbitrary size, relies on 
 * exploiting similarity between bytes of consecutive elements to reduce the size
 *
 * D conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/attributecodec.cpp
 */

import resources.all;

private {
    import core.stdc.string : memcpy, memset;
}

final class MeshoptAttributes {
public:
    void decode(ubyte[] inputBytes, ubyte[] outputBytes, uint vertexSize, uint vertexCount) {
        throwIf(vertexSize == 0 || vertexSize > 256, "Invalid byteStride %s", vertexSize);
        throwIf(vertexSize % 4 != 0, "byteStride must be a multiple of 4");

        throwIf(0 != meshopt_decodeVertexBuffer(outputBytes.ptr, vertexCount, vertexSize, inputBytes.ptr, inputBytes.length));
    }
private:
    const(uint)[4] kBitsV0 = [0, 2, 4, 8];
    const(uint)[5] kBitsV1 = [0, 1, 2, 4, 8];

    enum HEADER_MAJOR             = 0xa0;
    enum HEADER_SUPPORTED_VERSION = 1;

    enum kVertexBlockSizeBytes = 8192;
    enum kVertexBlockMaxSize   = 256;
    enum kByteGroupSize        = 16;
    enum kByteGroupDecodeLimit = 24;
    enum kTailMinSizeV0        = 32;
    enum kTailMinSizeV1        = 24;

    const(ubyte)* decodeBytesGroup(const(ubyte)* data, ubyte* buffer, uint switchBits) {

        ubyte byte_, enc, encv;
        const(ubyte)* data_var;

        void READ() { byte_ = *data++; }

        void NEXT(uint bits) {
            enc       = byte_ >> (8 - bits);
            byte_   <<= bits;
            encv      = *data_var;
            *buffer++ = (enc == (1 << bits) - 1) ? encv : enc;
            data_var += (enc == (1 << bits) - 1);
        }

        switch(switchBits) {
        case 0:
            memset(buffer, 0, kByteGroupSize);
            return data;
        case 1:
            data_var = data + 2;

            // 2 groups with 8 1-bit values in each byte (reversed from the order in other groups)
            READ();
            byte_ = cast(ubyte)(((byte_ * 0x80200802UL) & 0x0884422110UL) * 0x0101010101UL >> 32);
            NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1);
            READ();
            byte_ = cast(ubyte)(((byte_ * 0x80200802UL) & 0x0884422110UL) * 0x0101010101UL >> 32);
            NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1), NEXT(1);

            return data_var;
        case 2:
            data_var = data + 4;

            // 4 groups with 4 2-bit values in each byte
            READ(), NEXT(2), NEXT(2), NEXT(2), NEXT(2);
            READ(), NEXT(2), NEXT(2), NEXT(2), NEXT(2);
            READ(), NEXT(2), NEXT(2), NEXT(2), NEXT(2);
            READ(), NEXT(2), NEXT(2), NEXT(2), NEXT(2);

            return data_var;
        case 4:
            data_var = data + 8;

            // 8 groups with 2 4-bit values in each byte
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);
            READ(), NEXT(4), NEXT(4);

            return data_var;
        case 8:
            memcpy(buffer, data, kByteGroupSize);
            return data + kByteGroupSize;
        default:
            assert(!"Unexpected bit length"); // unreachable
            return data;
        }
    }

    const(ubyte)* decodeBytes(const(ubyte)* data, const(ubyte)* data_end, ubyte* buffer, size_t buffer_size, const(uint)* bits) {
        assert(buffer_size % kByteGroupSize == 0);

        // round number of groups to 4 to get number of header bytes
        size_t header_size = (buffer_size / kByteGroupSize + 3) / 4;
        if(cast(size_t)(data_end - data) < header_size)
            return null;

        const(ubyte)* header = data;
        data += header_size;

        for(size_t i = 0; i < buffer_size; i += kByteGroupSize) {
            if(cast(size_t)(data_end - data) < kByteGroupDecodeLimit)
                return null;

            size_t header_offset = i / kByteGroupSize;
            int bitsk = (header[header_offset / 4] >> ((header_offset % 4) * 2)) & 3;

            data = decodeBytesGroup(data, buffer + i, bits[bitsk]);
        }

        return data;
    }

    uint rotate(uint v, int r) {
        return (v << r) | (v >> ((32 - r) & 31));
    }
    T unzigzag(T)(T v) {
        return cast(T)(0 - (v & 1)) ^ (v >> 1);
    }
    void decodeDeltas1(T, bool Xor)(const(ubyte)* buffer, ubyte* transposed, size_t vertex_count, size_t vertex_size, const(ubyte)* last_vertex, int rot) {
        for(size_t k = 0; k < 4; k += T.sizeof) {
            size_t vertex_offset = k;

            T p = last_vertex[0];
            for(size_t j = 1; j < T.sizeof; ++j)
                p |= last_vertex[j] << (8 * j);

            for (size_t i = 0; i < vertex_count; ++i) {
                T v = buffer[i];
                for(size_t j = 1; j < T.sizeof; ++j)
                    v |= buffer[i + vertex_count * j] << (8 * j);

                v = Xor ? cast(T)(rotate(v, rot) ^ p) : cast(T)(unzigzag(v) + p);

                for(size_t j = 0; j < T.sizeof; ++j)
                    transposed[vertex_offset + j] = cast(ubyte)(v >> (j * 8));

                p = v;

                vertex_offset += vertex_size;
            }

            buffer += vertex_count * T.sizeof;
            last_vertex += T.sizeof;
        }
    }
    
    const(ubyte)* decodeVertexBlock(const(ubyte)* data, const(ubyte)* data_end, ubyte* vertex_data, size_t vertex_count, size_t vertex_size, ubyte[256] last_vertex, const(ubyte)* channels, int version_)
    {
        assert(vertex_count > 0 && vertex_count <= kVertexBlockMaxSize);

        ubyte[kVertexBlockMaxSize * 4] buffer;
        ubyte[kVertexBlockSizeBytes] transposed;

        size_t vertex_count_aligned = (vertex_count + kByteGroupSize - 1) & ~(kByteGroupSize - 1);
        assert(vertex_count <= vertex_count_aligned);

        size_t control_size = version_ == 0 ? 0 : vertex_size / 4;
        if(cast(size_t)(data_end - data) < control_size)
            return null;

        const(ubyte)* control = data;
        data += control_size;

        for(size_t k = 0; k < vertex_size; k += 4) {
            ubyte ctrl_byte = version_ == 0 ? 0 : control[k / 4];

            for(size_t j = 0; j < 4; ++j) {
                int ctrl = (ctrl_byte >> (j * 2)) & 3;

                if(ctrl == 3) {
                    // literal encoding
                    if(size_t(data_end - data) < vertex_count)
                        return null;

                    memcpy(buffer.ptr + j * vertex_count, data, vertex_count);
                    data += vertex_count;
                }
                else if (ctrl == 2)
                {
                    // zero encoding
                    memset(buffer.ptr + j * vertex_count, 0, vertex_count);
                }
                else {
                    data = decodeBytes(data, data_end, buffer.ptr + j * vertex_count, vertex_count_aligned, version_ == 0 ? kBitsV0.ptr : kBitsV1.ptr + ctrl);
                    if(!data)
                        return null;
                }
            }

            int channel = version_ == 0 ? 0 : channels[k / 4];

            switch (channel & 3)
            {
            case 0:
                decodeDeltas1!(ubyte, false)(buffer.ptr, transposed.ptr + k, vertex_count, vertex_size, last_vertex.ptr + k, 0);
                break;
            case 1:
                decodeDeltas1!(ushort, false)(buffer.ptr, transposed.ptr + k, vertex_count, vertex_size, last_vertex.ptr + k, 0);
                break;
            case 2:
                decodeDeltas1!(uint, true)(buffer.ptr, transposed.ptr + k, vertex_count, vertex_size, last_vertex.ptr + k, (32 - (channel >> 4)) & 31);
                break;
            default:
                return null; // invalid channel type
            }
        }

        memcpy(vertex_data, transposed.ptr, vertex_count * vertex_size);

        memcpy(last_vertex.ptr, &transposed[vertex_size * (vertex_count - 1)], vertex_size);

        return data;
    }

    size_t getVertexBlockSize(size_t vertex_size) {
        size_t result = (kVertexBlockSizeBytes / vertex_size) & ~(kByteGroupSize - 1);
        return (result < kVertexBlockMaxSize) ? result : kVertexBlockMaxSize;
    }
    
    int meshopt_decodeVertexBuffer(void* destination, size_t vertex_count, size_t vertex_size, const(ubyte)* buffer, size_t buffer_size)
    {
        ubyte* vertex_data = cast(ubyte*)(destination);

        const(ubyte)* data = buffer;
        const(ubyte)* data_end = buffer + buffer_size;

        if(cast(size_t)(data_end - data) < 1)
            return -2;

        ubyte data_header = *data++;

        if((data_header & 0xf0) != HEADER_MAJOR)
            return -1;

        int version_ = data_header & 0x0f;
        if(version_ > HEADER_SUPPORTED_VERSION)
            return -1;

        size_t tail_size = vertex_size + (version_ == 0 ? 0 : vertex_size / 4);
        size_t tail_size_min = version_ == 0 ? kTailMinSizeV0 : kTailMinSizeV1;
        size_t tail_size_pad = tail_size < tail_size_min ? tail_size_min : tail_size;

        if (size_t(data_end - data) < tail_size_pad)
            return -2;

        const(ubyte)* tail = data_end - tail_size;

        ubyte[256] last_vertex;
        memcpy(last_vertex.ptr, tail, vertex_size);

        const(ubyte)* channels = version_ == 0 ? null : tail + vertex_size;

        size_t vertex_block_size = getVertexBlockSize(vertex_size);

        size_t vertex_offset = 0;

        while(vertex_offset < vertex_count) {
            size_t block_size = (vertex_offset + vertex_block_size < vertex_count) ? vertex_block_size : vertex_count - vertex_offset;

            data = decodeVertexBlock(data, data_end, vertex_data + vertex_offset * vertex_size, block_size, vertex_size, last_vertex, channels, version_);
            if(!data)
                return -2;

            vertex_offset += block_size;
        }

        if (cast(size_t)(data_end - data) != tail_size_pad)
            return -3;

        return 0;
    }
}
