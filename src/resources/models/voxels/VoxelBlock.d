module resources.models.voxels.VoxelBlock;

import resources        : BZip3;
import maths            : uint3, float4;
import common.utils     : as, throwIf;
import std.format       : format;
import std.stdio        : File;

/**
 * Represent a block of 1 byte voxels of arbitrary size.
 */
final class VoxelBlock {
public:
    const uint3 size;
    ubyte[] voxels;
    float4[256] palette;

    this(uint3 size) {
        this.size = size;
        this.mul = uint3(1, size.x, size.x*size.y);
        this.voxels.length = size.x * size.y * size.z;
        this.palette = DEFAULT_PALETTE.dup;
    }
    /** Set all voxels to value */
    void clear(ubyte value) {
        voxels[] = value;
    }
    /** Return the number of voxels with the given value */
    uint count(ubyte value) {
        import std.algorithm : count;
        return voxels.count(value).as!uint;
    }
    /** Return true if the voxel at pos has the given value */
    bool isValue(uint3 pos, ubyte value) {
        return voxels[toIndex(pos)] == value;
    }
    /** Set the voxel at pos to value */
    void set(uint3 pos, ubyte value) {
        voxels[toIndex(pos)] = value;
    }
    /** Set all voxels in the range [offset, offset+size) to value */
    void set(uint3 offset, uint size, ubyte value) {
        assert(size > 0, "size must be > 0");
        assert((offset+size).allLTE(this.size), "%s+%s is outside of the voxel grid".format(offset, size));

        uint indexZ = toIndex(offset);
        foreach(z; 0..size) {
            uint indexY = indexZ;
            foreach(y; 0..size) {
                uint indexX = indexY;
                foreach(x; 0..size) {
                    voxels[indexX] = value;
                    indexX++;
                }
                indexY += Y();
            }
            indexZ += Z();
        }
    }
    /** Return true if the voxel at pos is not 0 */
    bool isSet(uint3 pos) {
        return voxels[toIndex(pos)] != 0;
    }
    /** Return true if any voxel in the range [offset, offset+size) is not 0 */
    bool anySet(uint3 offset, uint size) {
        assert(size > 0, "size must be > 0");
        assert((offset+size).allLTE(this.size), "%s+%s is outside of the voxel grid".format(offset, size));

        uint indexZ = toIndex(offset);
        foreach(z; 0..size) {
            uint indexY = indexZ;
            foreach(y; 0..size) {
                uint indexX = indexY;
                foreach(x; 0..size) {
                    if(voxels[indexX] != 0) return true;
                    indexX++;
                }
                indexY += Y();
            }
            indexZ += Z();
        }
        return false;
    }
    /** Return true if all voxels in the range [offset, offset+size) are not 0 */
    bool allSet(uint3 offset, uint size) {
        assert(size > 0, "size must be > 0");
        assert((offset+size).allLTE(this.size), "%s+%s is outside of the voxel grid".format(offset, size));

        uint indexZ = toIndex(offset);
        foreach(z; 0..size) {
            uint indexY = indexZ;
            foreach(y; 0..size) {
                uint indexX = indexY;
                foreach(x; 0..size) {
                    if(voxels[indexX] == 0) return false;
                    indexX++;
                }
                indexY += Y();
            }
            indexZ += Z();
        }
        return true;
    }
    /** Return true if all voxels in the range [offset1, offset1+size) are equal to the voxels in the range [offset2, offset2+size) */
    bool areaEqual(uint3 offset1, uint3 offset2, uint size) {
        assert(size > 0, "size must be > 0");
        assert((offset1+size).allLTE(this.size), "%s+%s is outside of the voxel grid".format(offset1, size));
        assert((offset2+size).allLTE(this.size), "%s+%s is outside of the voxel grid".format(offset2, size));

        uint index1Z = toIndex(offset1);
        uint index2Z = toIndex(offset2);
        foreach(z; 0..size) {
            uint index1Y = index1Z;
            uint index2Y = index2Z;
            foreach(y; 0..size) {
                uint index1X = index1Y;
                uint index2X = index2Y;
                foreach(x; 0..size) {
                    if(voxels[index1X] != voxels[index2X]) return false;
                    index1X++;
                    index2X++;
                }
                index1Y += Y();
                index2Y += Y();
            }
            index1Z += Z();
            index2Z += Z();
        }
        return true;
    }

    /**
     * Write to a file with the following format:
     *  [0    : 4 bytes]      uint    = x size
     *  [4    : 4 bytes]      uint    = y size
     *  [8    : 4 bytes]      uint    = z size
     *  [12   : 4 bytes]      uint    = P = palette size compressed
     *  [16   : 4 bytes]      uint    = V = voxel data size compressed
     *  [20   : 256*16 bytes] ubyte[] = palette (256 RGBA colours) - compressed using BZip3
     *  [20+P : x*y*z bytes]  ubyte[] = voxel array - 1 byte per voxel - compressed using BZip3
     */
    void write(string filename) {
        
        File file = File(filename, "wb");
        scope(exit) file.close();

        ubyte[] squashedPalette = BZip3.compress(palette.ptr.as!(ubyte*)[0..256*float4.sizeof], 1);
        ubyte[] squashedVoxels = BZip3.compress(voxels, 32);

        file.rawWrite([size.x, size.y, size.z]);
        file.rawWrite([squashedPalette.length.as!uint, squashedVoxels.length.as!uint]);
        file.rawWrite(squashedPalette);
        file.rawWrite(squashedVoxels);
    }
    /**
     * Read from a file (see write() for format)
     */
    static VoxelBlock read(string filename) {
        File file = File(filename, "rb");
        scope(exit) file.close();

        uint[5] temp;
        file.rawRead(temp);
        uint3 sz = uint3(temp[0], temp[1], temp[2]);
        uint paletteSize = temp[3];
        uint voxelsSize = temp[4];

        ubyte[] paletteData = file.rawRead(new ubyte[paletteSize]);
        ubyte[] voxelsData = file.rawRead(new ubyte[voxelsSize]);

        VoxelBlock v = new VoxelBlock(sz);
        v.voxels = BZip3.decompress(voxelsData);
        v.palette = BZip3.decompress(paletteData).ptr.as!(float4*)[0..256];
        return v;
    }
    static immutable(float4)[] DEFAULT_PALETTE = [
        float4(0.00, 0.00, 0.00, 0.00), float4(1.00, 1.00, 1.00, 1.00), float4(1.00, 1.00, 0.80, 1.00), float4(1.00, 1.00, 0.60, 1.00), float4(1.00, 1.00, 0.40, 1.00), float4(1.00, 1.00, 0.20, 1.00), float4(1.00, 1.00, 0.00, 1.00), float4(1.00, 0.80, 1.00, 1.00), float4(1.00, 0.80, 0.80, 1.00), float4(1.00, 0.80, 0.60, 1.00), float4(1.00, 0.80, 0.40, 1.00), float4(1.00, 0.80, 0.20, 1.00), float4(1.00, 0.80, 0.00, 1.00), float4(1.00, 0.60, 1.00, 1.00), float4(1.00, 0.60, 0.80, 1.00), float4(1.00, 0.60, 0.60, 1.00),
        float4(1.00, 0.60, 0.40, 1.00), float4(1.00, 0.60, 0.20, 1.00), float4(1.00, 0.60, 0.00, 1.00), float4(1.00, 0.40, 1.00, 1.00), float4(1.00, 0.40, 0.80, 1.00), float4(1.00, 0.40, 0.60, 1.00), float4(1.00, 0.40, 0.40, 1.00), float4(1.00, 0.40, 0.20, 1.00), float4(1.00, 0.40, 0.00, 1.00), float4(1.00, 0.20, 1.00, 1.00), float4(1.00, 0.20, 0.80, 1.00), float4(1.00, 0.20, 0.60, 1.00), float4(1.00, 0.20, 0.40, 1.00), float4(1.00, 0.20, 0.20, 1.00), float4(1.00, 0.20, 0.00, 1.00), float4(1.00, 0.00, 1.00, 1.00),
        float4(1.00, 0.00, 0.80, 1.00), float4(1.00, 0.00, 0.60, 1.00), float4(1.00, 0.00, 0.40, 1.00), float4(1.00, 0.00, 0.20, 1.00), float4(1.00, 0.00, 0.00, 1.00), float4(0.80, 1.00, 1.00, 1.00), float4(0.80, 1.00, 0.80, 1.00), float4(0.80, 1.00, 0.60, 1.00), float4(0.80, 1.00, 0.40, 1.00), float4(0.80, 1.00, 0.20, 1.00), float4(0.80, 1.00, 0.00, 1.00), float4(0.80, 0.80, 1.00, 1.00), float4(0.80, 0.80, 0.80, 1.00), float4(0.80, 0.80, 0.60, 1.00), float4(0.80, 0.80, 0.40, 1.00), float4(0.80, 0.80, 0.20, 1.00),
        float4(0.80, 0.80, 0.00, 1.00), float4(0.80, 0.60, 1.00, 1.00), float4(0.80, 0.60, 0.80, 1.00), float4(0.80, 0.60, 0.60, 1.00), float4(0.80, 0.60, 0.40, 1.00), float4(0.80, 0.60, 0.20, 1.00), float4(0.80, 0.60, 0.00, 1.00), float4(0.80, 0.40, 1.00, 1.00), float4(0.80, 0.40, 0.80, 1.00), float4(0.80, 0.40, 0.60, 1.00), float4(0.80, 0.40, 0.40, 1.00), float4(0.80, 0.40, 0.20, 1.00), float4(0.80, 0.40, 0.00, 1.00), float4(0.80, 0.20, 1.00, 1.00), float4(0.80, 0.20, 0.80, 1.00), float4(0.80, 0.20, 0.60, 1.00),
        float4(0.80, 0.20, 0.40, 1.00), float4(0.80, 0.20, 0.20, 1.00), float4(0.80, 0.20, 0.00, 1.00), float4(0.80, 0.00, 1.00, 1.00), float4(0.80, 0.00, 0.80, 1.00), float4(0.80, 0.00, 0.60, 1.00), float4(0.80, 0.00, 0.40, 1.00), float4(0.80, 0.00, 0.20, 1.00), float4(0.80, 0.00, 0.00, 1.00), float4(0.60, 1.00, 1.00, 1.00), float4(0.60, 1.00, 0.80, 1.00), float4(0.60, 1.00, 0.60, 1.00), float4(0.60, 1.00, 0.40, 1.00), float4(0.60, 1.00, 0.20, 1.00), float4(0.60, 1.00, 0.00, 1.00), float4(0.60, 0.80, 1.00, 1.00),
        float4(0.60, 0.80, 0.80, 1.00), float4(0.60, 0.80, 0.60, 1.00), float4(0.60, 0.80, 0.40, 1.00), float4(0.60, 0.80, 0.20, 1.00), float4(0.60, 0.80, 0.00, 1.00), float4(0.60, 0.60, 1.00, 1.00), float4(0.60, 0.60, 0.80, 1.00), float4(0.60, 0.60, 0.60, 1.00), float4(0.60, 0.60, 0.40, 1.00), float4(0.60, 0.60, 0.20, 1.00), float4(0.60, 0.60, 0.00, 1.00), float4(0.60, 0.40, 1.00, 1.00), float4(0.60, 0.40, 0.80, 1.00), float4(0.60, 0.40, 0.60, 1.00), float4(0.60, 0.40, 0.40, 1.00), float4(0.60, 0.40, 0.20, 1.00),
        float4(0.60, 0.40, 0.00, 1.00), float4(0.60, 0.20, 1.00, 1.00), float4(0.60, 0.20, 0.80, 1.00), float4(0.60, 0.20, 0.60, 1.00), float4(0.60, 0.20, 0.40, 1.00), float4(0.60, 0.20, 0.20, 1.00), float4(0.60, 0.20, 0.00, 1.00), float4(0.60, 0.00, 1.00, 1.00), float4(0.60, 0.00, 0.80, 1.00), float4(0.60, 0.00, 0.60, 1.00), float4(0.60, 0.00, 0.40, 1.00), float4(0.60, 0.00, 0.20, 1.00), float4(0.60, 0.00, 0.00, 1.00), float4(0.40, 1.00, 1.00, 1.00), float4(0.40, 1.00, 0.80, 1.00), float4(0.40, 1.00, 0.60, 1.00),
        float4(0.40, 1.00, 0.40, 1.00), float4(0.40, 1.00, 0.20, 1.00), float4(0.40, 1.00, 0.00, 1.00), float4(0.40, 0.80, 1.00, 1.00), float4(0.40, 0.80, 0.80, 1.00), float4(0.40, 0.80, 0.60, 1.00), float4(0.40, 0.80, 0.40, 1.00), float4(0.40, 0.80, 0.20, 1.00), float4(0.40, 0.80, 0.00, 1.00), float4(0.40, 0.60, 1.00, 1.00), float4(0.40, 0.60, 0.80, 1.00), float4(0.40, 0.60, 0.60, 1.00), float4(0.40, 0.60, 0.40, 1.00), float4(0.40, 0.60, 0.20, 1.00), float4(0.40, 0.60, 0.00, 1.00), float4(0.40, 0.40, 1.00, 1.00),
        float4(0.40, 0.40, 0.80, 1.00), float4(0.40, 0.40, 0.60, 1.00), float4(0.40, 0.40, 0.40, 1.00), float4(0.40, 0.40, 0.20, 1.00), float4(0.40, 0.40, 0.00, 1.00), float4(0.40, 0.20, 1.00, 1.00), float4(0.40, 0.20, 0.80, 1.00), float4(0.40, 0.20, 0.60, 1.00), float4(0.40, 0.20, 0.40, 1.00), float4(0.40, 0.20, 0.20, 1.00), float4(0.40, 0.20, 0.00, 1.00), float4(0.40, 0.00, 1.00, 1.00), float4(0.40, 0.00, 0.80, 1.00), float4(0.40, 0.00, 0.60, 1.00), float4(0.40, 0.00, 0.40, 1.00), float4(0.40, 0.00, 0.20, 1.00),
        float4(0.40, 0.00, 0.00, 1.00), float4(0.20, 1.00, 1.00, 1.00), float4(0.20, 1.00, 0.80, 1.00), float4(0.20, 1.00, 0.60, 1.00), float4(0.20, 1.00, 0.40, 1.00), float4(0.20, 1.00, 0.20, 1.00), float4(0.20, 1.00, 0.00, 1.00), float4(0.20, 0.80, 1.00, 1.00), float4(0.20, 0.80, 0.80, 1.00), float4(0.20, 0.80, 0.60, 1.00), float4(0.20, 0.80, 0.40, 1.00), float4(0.20, 0.80, 0.20, 1.00), float4(0.20, 0.80, 0.00, 1.00), float4(0.20, 0.60, 1.00, 1.00), float4(0.20, 0.60, 0.80, 1.00), float4(0.20, 0.60, 0.60, 1.00),
        float4(0.20, 0.60, 0.40, 1.00), float4(0.20, 0.60, 0.20, 1.00), float4(0.20, 0.60, 0.00, 1.00), float4(0.20, 0.40, 1.00, 1.00), float4(0.20, 0.40, 0.80, 1.00), float4(0.20, 0.40, 0.60, 1.00), float4(0.20, 0.40, 0.40, 1.00), float4(0.20, 0.40, 0.20, 1.00), float4(0.20, 0.40, 0.00, 1.00), float4(0.20, 0.20, 1.00, 1.00), float4(0.20, 0.20, 0.80, 1.00), float4(0.20, 0.20, 0.60, 1.00), float4(0.20, 0.20, 0.40, 1.00), float4(0.20, 0.20, 0.20, 1.00), float4(0.20, 0.20, 0.00, 1.00), float4(0.20, 0.00, 1.00, 1.00),
        float4(0.20, 0.00, 0.80, 1.00), float4(0.20, 0.00, 0.60, 1.00), float4(0.20, 0.00, 0.40, 1.00), float4(0.20, 0.00, 0.20, 1.00), float4(0.20, 0.00, 0.00, 1.00), float4(0.00, 1.00, 1.00, 1.00), float4(0.00, 1.00, 0.80, 1.00), float4(0.00, 1.00, 0.60, 1.00), float4(0.00, 1.00, 0.40, 1.00), float4(0.00, 1.00, 0.20, 1.00), float4(0.00, 1.00, 0.00, 1.00), float4(0.00, 0.80, 1.00, 1.00), float4(0.00, 0.80, 0.80, 1.00), float4(0.00, 0.80, 0.60, 1.00), float4(0.00, 0.80, 0.40, 1.00), float4(0.00, 0.80, 0.20, 1.00),
        float4(0.00, 0.80, 0.00, 1.00), float4(0.00, 0.60, 1.00, 1.00), float4(0.00, 0.60, 0.80, 1.00), float4(0.00, 0.60, 0.60, 1.00), float4(0.00, 0.60, 0.40, 1.00), float4(0.00, 0.60, 0.20, 1.00), float4(0.00, 0.60, 0.00, 1.00), float4(0.00, 0.40, 1.00, 1.00), float4(0.00, 0.40, 0.80, 1.00), float4(0.00, 0.40, 0.60, 1.00), float4(0.00, 0.40, 0.40, 1.00), float4(0.00, 0.40, 0.20, 1.00), float4(0.00, 0.40, 0.00, 1.00), float4(0.00, 0.20, 1.00, 1.00), float4(0.00, 0.20, 0.80, 1.00), float4(0.00, 0.20, 0.60, 1.00),
        float4(0.00, 0.20, 0.40, 1.00), float4(0.00, 0.20, 0.20, 1.00), float4(0.00, 0.20, 0.00, 1.00), float4(0.00, 0.00, 1.00, 1.00), float4(0.00, 0.00, 0.80, 1.00), float4(0.00, 0.00, 0.60, 1.00), float4(0.00, 0.00, 0.40, 1.00), float4(0.00, 0.00, 0.20, 1.00), float4(0.93, 0.00, 0.00, 1.00), float4(0.86, 0.00, 0.00, 1.00), float4(0.73, 0.00, 0.00, 1.00), float4(0.66, 0.00, 0.00, 1.00), float4(0.53, 0.00, 0.00, 1.00), float4(0.46, 0.00, 0.00, 1.00), float4(0.33, 0.00, 0.00, 1.00), float4(0.27, 0.00, 0.00, 1.00),
        float4(0.13, 0.00, 0.00, 1.00), float4(0.07, 0.00, 0.00, 1.00), float4(0.00, 0.93, 0.00, 1.00), float4(0.00, 0.86, 0.00, 1.00), float4(0.00, 0.73, 0.00, 1.00), float4(0.00, 0.66, 0.00, 1.00), float4(0.00, 0.53, 0.00, 1.00), float4(0.00, 0.46, 0.00, 1.00), float4(0.00, 0.33, 0.00, 1.00), float4(0.00, 0.27, 0.00, 1.00), float4(0.00, 0.13, 0.00, 1.00), float4(0.00, 0.07, 0.00, 1.00), float4(0.00, 0.00, 0.93, 1.00), float4(0.00, 0.00, 0.86, 1.00), float4(0.00, 0.00, 0.73, 1.00), float4(0.00, 0.00, 0.66, 1.00),
        float4(0.00, 0.00, 0.53, 1.00), float4(0.00, 0.00, 0.46, 1.00), float4(0.00, 0.00, 0.33, 1.00), float4(0.00, 0.00, 0.27, 1.00), float4(0.00, 0.00, 0.13, 1.00), float4(0.00, 0.00, 0.07, 1.00), float4(0.93, 0.93, 0.93, 1.00), float4(0.86, 0.86, 0.86, 1.00), float4(0.73, 0.73, 0.73, 1.00), float4(0.66, 0.66, 0.66, 1.00), float4(0.53, 0.53, 0.53, 1.00), float4(0.46, 0.46, 0.46, 1.00), float4(0.33, 0.33, 0.33, 1.00), float4(0.27, 0.27, 0.27, 1.00), float4(0.13, 0.13, 0.13, 1.00), float4(0.07, 0.07, 0.07, 1.00),
    ];
private:
    const uint3 mul;

    uint Y() { return size.x; }
    uint Z() { return size.x * size.y; }

    uint toIndex(uint3 pos) {
        assert(pos.allLT(size), "Position %s is outside of the voxel grid".format(pos));
        return pos.dot(mul);
    }
}
