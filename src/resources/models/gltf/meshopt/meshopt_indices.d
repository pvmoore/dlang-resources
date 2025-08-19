module resources.models.gltf.meshopt.meshopt_indices;

/**
 * Mode 2: INDICES. Suitable for storing indices that don't represent triangle lists, relies 
 * on exploiting similarity between consecutive elements.
 *
 * D conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/indexcodec.cpp 
 */

import resources.all;

final class MeshoptIndices {
public:
    void decode(ubyte[] inputBytes, ubyte[] outputBytes, uint vertexSize, uint vertexCount) {

        throwIf(0 != meshopt_decodeIndexSequence(outputBytes.ptr, vertexCount, vertexSize, inputBytes.ptr, inputBytes.length));
    }
private:
    enum HEADER_MAJOR             = 0xd0;
    enum HEADER_SUPPORTED_VERSION = 1;

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
    
    int meshopt_decodeIndexSequence(void* destination, size_t index_count, size_t index_size, const(ubyte)* buffer, size_t buffer_size) {

        // the minimum valid encoding is header, 1 byte per index and a 4-byte tail
        if (buffer_size < 1 + index_count + 4)
            return -2;

        if ((buffer[0] & 0xf0) != HEADER_MAJOR)
            return -1;

        int version_ = buffer[0] & 0x0f;
        if(version_ > HEADER_SUPPORTED_VERSION)
            return -1;

        const(ubyte)* data = buffer + 1;
        const(ubyte)* data_safe_end = buffer + buffer_size - 4;

        uint[2] last;

        for(size_t i = 0; i < index_count; ++i) {
            // make sure we have enough data to read
            // each index reads at most 5 bytes of data; there's a 4 byte tail after data_safe_end
            // after this we can be sure we can read without extra bounds checks
            if (data >= data_safe_end)
                return -2;

            uint v = decodeVByte(data);

            // decode the index of the last baseline
            uint current = v & 1;
            v >>= 1;

            // reconstruct index as a delta
            uint d = (v >> 1) ^ -int(v & 1);
            uint index = last[current] + d;

            // update last for the next iteration that uses it
            last[current] = index;

            if (index_size == 2)
            {
                destination.as!(ushort*)[i] = cast(ushort)(index);
            }
            else
            {
                destination.as!(uint*)[i] = index;
            }
        }

        // we should've read all data bytes and stopped at the boundary between data and tail
        if(data != data_safe_end)
            return -3;

        return 0;
    }
}
