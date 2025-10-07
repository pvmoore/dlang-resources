module resources.models.voxels.Voxeliser;

import resources : Obj;
import resources.models.gltf;
import resources.models.voxels.VoxelBlock;

import maths        : int3, uint3, float2, float3, float4, mat4, AABB, Triangle, Ray, maxOf, anglef, degrees;
import common.utils : as, throwIf, throwIfNot;
import common.containers : Stack;
import std.stdio : writefln;
import std.math  : round;
import std.range : array;
import std.algorithm : map;

/**
 * Convert 3D data to a voxelised version.
 *
 *
 */
final class Voxeliser {
public:
    this() {
        this.palette = VoxelBlock.DEFAULT_PALETTE.dup;
    }

    // void addTexture(string filename) {
    //     // todo
    // }
   
    void rotate(anglef x, anglef y, anglef z) {
        this.xRotation = x;
        this.yRotation = y;
        this.zRotation = z;
    }
    void setColour(uint index, float4 colour) {
        palette[index] = colour;
    }

    void addFace(Triangle t, float4 colour) {
        addFace(Face(t, colour, getColourIndex(colour)));
    }
    void addGeometry(Obj obj) {
        foreach(f; obj.faces) {
            addFace(Triangle(obj.vertex(f, 0), obj.vertex(f, 1), obj.vertex(f, 2)), float4(1,0,0,1));
        }
    }
    void addGeometry(GLTF gltf) {

        void applyMatrix(float3[] array, float[16] m) {
            mat4 m2 = mat4.columnMajor(m);
            foreach(i; 0..array.length) {
                float4 result = m2 * float4(array[i], 1);
                array[i] = result.xyz;
            }
        }
        foreach(meshIndex, m; gltf.meshes) {
            writefln("Mesh [%s] %s", meshIndex, m.name);
            foreach(j, p; m.primitives) {
                throwIf(p.mode != MeshPrimitive.Mode.TRIANGLES, "Only triangles are supported");
                throwIfNot(p.hasAttribute("POSITION"), "No POSITION attributes");

                writefln("  Primitive [%s] %s", j, p.mode);
                writefln("    Attributes: %s", p.attributes.keys());
                float4 baseColour = float4(1,1,1,1);
                if(auto matId = p.material) {
                    auto mat = gltf.materials[matId.get()];
                    if(mat.pbrMetallicRoughness) {
                        baseColour = *mat.pbrMetallicRoughness.get().baseColorFactor.ptr.as!(float4*);
                    }
                    writefln("    Colour    : %s", baseColour);
                }
                auto indices   = getIndicesArray(gltf, p);
                auto positions = getAttributeDataArray!float3(gltf, p, "POSITION");
                auto uvs       = getAttributeDataArray!float2(gltf, p, "TEXCOORD_0");
                writefln("    indices   : %s", indices.length);
                writefln("    positions : %s", positions.length);
                writefln("    uvs       : %s", uvs.length);

                // Check Nodes for transformations
                foreach(n; gltf.nodes) {

                    // Apply matrix to the following nodes
                    foreach(ch; n.children) {
                        auto node = gltf.nodes[ch];
                        if(!node.mesh.isNull()) {
                            uint childMeshIndex = node.mesh.get();
                            if(childMeshIndex == meshIndex) {
                                // This is our current mesh
                                writefln("Applying matrix to mesh %s vertices %s", childMeshIndex, n.matrix);
                                applyMatrix(positions, n.matrix);
                            }
                        }
                    }
                }

                // ignore uvs for now

                // Add faces
                foreach(k; 0..indices.length/3) {
                    Triangle t = Triangle(positions[indices[k*3+0]], positions[indices[k*3+1]], positions[indices[k*3+2]]);
                    addFace(t, baseColour);
                }
            }
        }
    }
    
    /**
     *
     *
     * params:
     *     voxelDimension : number of voxels in the longest dimension. Other dimensions will be scaled accordingly
     *     fill           : true to fill any enclosed spaces with voxels
     */
    VoxelBlock voxelise(uint voxelsDimension, bool fill) {
        throwIf(faces.length < 1, "No faces added");

        applyRotation();

        AABB aabb = faces[0].t.aabb();
        foreach(f; faces[1..$]) {
            aabb.enclose(f.t.aabb());
        }
        this.voxelSize = aabb.size().max() / voxelsDimension;

        int3 min = (aabb.min() / voxelSize).round().to!int;
        int3 max = (aabb.max() / voxelSize).round().to!int;

        this.voxelsDimension = voxelsDimension;
        this.minVertex       = aabb.min();
        this.size            = (max - min).to!uint;
        this.mul             = uint3(1, size.x, size.x*size.y);
        writefln("size = %s", size);

        this.voxels.length = size.x * size.y * size.z;
        writefln("voxels.length = %s", voxels.length);

        rasterise();

        if(fill) {
            fillInterior();
        }

        VoxelBlock block = new VoxelBlock(size);
        block.voxels = voxels;
        block.palette = palette;
        return block;
    }
private:
    enum ZERO_ANGLE = 0.degrees;

    Face[] faces;
    float4[] palette;
    anglef xRotation = ZERO_ANGLE;
    anglef yRotation = ZERO_ANGLE;
    anglef zRotation = ZERO_ANGLE;

    uint voxelsDimension;
    float voxelSize;
    float3 minVertex;
    uint3 size;
    uint3 mul;
    ubyte[] voxels;

    static struct Face {
        Triangle t;
        float4 colour;
        uint colourIndex;
        //int textureIndex;   // todo
        //float2 uv;          // todo
    }
    void addFace(Face face) {
        faces ~= face;
    }
    void applyRotation() {
        if(xRotation != ZERO_ANGLE || yRotation != ZERO_ANGLE || zRotation != ZERO_ANGLE) {
            mat4 m = mat4.rotate(xRotation, yRotation, zRotation);
            foreach(ref f; faces) {
                f.t.p0 = f.t.p0 * m;
                f.t.p1 = f.t.p1 * m;
                f.t.p2 = f.t.p2 * m;
            }
        }
    }
    uint getColourIndex(float4 colour) {
        float lowestDistance = float.max;
        uint lowestIndex = 0;
        foreach(i, c; palette) {
            float dist = (c - colour).magnitude();
            if(dist < lowestDistance) {
                lowestDistance = dist;
                lowestIndex = i.as!uint;
            }
        }
        //writefln("estimated colour %s as %s %s", colour, lowestIndex, palette[lowestIndex]);
        return lowestIndex;
    }

    uint toGridIndex(float3 pos) {
        uint3 upos = ((pos - minVertex) / voxelSize).round().to!uint; // use round here?
        if(upos.anyGT(size)) return uint.max; 
        return upos.dot(mul);
    }
    void write(float3 pos, ubyte value) {
        uint i = toGridIndex(pos);
        if(i > voxels.length) return;
        voxels[i] = value;
    }

    void rasterise() {
        writefln("Rasterising");
        foreach(f; faces) {
            rasteriseFace(f);
        }
    }
    void rasteriseFace(Face f) {
        float3 a = f.t.p1 - f.t.p0;
        float3 b = f.t.p2 - f.t.p0;

        float aLen = a.length();
        float bLen = b.length();


        float longest = maxOf(aLen, bLen);
        uint numSteps = calculateNumSteps(longest);

        float3 aDelta = a / numSteps;
        float3 bDelta = b / numSteps;

        float3 start = f.t.p0;
        float3 end   = start;
        foreach(i; 0..numSteps) {

            float3 p = start;
            float3 c = end-p;
            float length = c.length();
            uint numInnerSteps = calculateNumSteps(length);
            float3 innerDelta = c / numInnerSteps;

            foreach(j; 0..numInnerSteps) {
                // todo - get the colour sample from f.colour or texture
                write(p, 1);
                p += innerDelta;
            }

            start += aDelta;
            end   += bDelta;
        }
    }
    uint calculateNumSteps(float len) {
        return ((len / voxelSize) * 4).as!uint;
    }
    void fillInterior() {
        // 1) Mark all cells that contain a voxel as SOLID
        // 2) Mark all cells that are definitely outside of the object by iterating each axis from the outside 
        //    to the inside until a non air cell is found
        // 3) Flood fill from these cells until all cells reachable from the outside are marked as outside
        // 4) All remaining air cells are inside

        writefln("Filling interior");

        enum Flag : ubyte{ UNKNOWN, OUTSIDE, SOLID }

        Flag[] flags = new Flag[voxels.length];

        const X = 1;
        const Y = size.x;
        const Z = size.x * size.y;

        uint toIndex(uint x, uint y, uint z) {
            return x + y*Y + z*Z;
        }

        ubyte getVoxel(uint x, uint y, uint z) {
            return voxels[toIndex(x, y, z)];
        }
        Flag getFlag(uint x, uint y, uint z) {
            uint i = toIndex(x, y, z);
            throwIf(i > flags.length, "Outside of voxel grid");
            return flags[i];
        }
        void setOutside(uint x, uint y, uint z) {
            flags[toIndex(x, y, z)] = Flag.OUTSIDE;
        }

        // Mark all cells that contain a voxel as SOLID
        foreach(i; 0..voxels.length) {
            if(voxels[i] != 0) {
                flags[i] = Flag.SOLID;
            }
        }

        // Mark definitely outside cells on the X axis
        foreach(z; 0..size.z) {
            foreach(y; 0..size.y) {
                for(auto x = 0; x<size.x && getVoxel(x, y, z) == 0; x++) {
                    if(getFlag(x, y, z) == Flag.UNKNOWN) {
                        setOutside(x, y, z);
                    }
                }
            }
        }
        // Mark definitely outside cells on the Y axis
        foreach(z; 0..size.z) {
            foreach(x; 0..size.x) {
                for(auto y = 0; y<size.y && getVoxel(x, y, z) == 0; y++) {
                    if(getFlag(x, y, z) == Flag.UNKNOWN) {
                        setOutside(x, y, z);
                    }
                }
            }
        }
        // Mark definitely outside cells on the Z axis
        foreach(y; 0..size.y) {
            foreach(x; 0..size.x) {
                for(auto z = 0; z<size.z && getVoxel(x, y, z) == 0; z++) {
                    if(getFlag(x, y, z) == Flag.UNKNOWN) {
                        setOutside(x, y, z);
                    }
                }
            }
        }

        // Collect all UNKNOWN cells that are adjacent to OUTSIDE cells 
        auto stack = new Stack!uint;
        uint index = 0;
        foreach(z; 0..size.z) {
            foreach(y; 0..size.y) {
                foreach(x; 0..size.x) {
                    if(flags[index] == Flag.OUTSIDE) {
                        if(x > 0 && flags[index-X] == Flag.UNKNOWN) {
                            stack.push(index - X);
                        }
                        if(x < size.x-1 && flags[index+X] == Flag.UNKNOWN) {
                            stack.push(index + X);
                        }
                        if(y > 0 && flags[index-Y] == Flag.UNKNOWN) {
                            stack.push(index - Y);
                        }
                        if(y < size.y-1 && flags[index+Y] == Flag.UNKNOWN) {
                            stack.push(index + Y);
                        }
                        if(z > 0 && flags[index-Z] == Flag.UNKNOWN) {
                            stack.push(index - Z);
                        }
                        if(z < size.z-1 && flags[index+Z] == Flag.UNKNOWN) {
                            stack.push(index + Z);
                        }
                    }
                    index++;
                }
            }
        }

        writefln("Flood filling outside voxels");

        // Flood fill from the collected cells until stack is empty
        while(!stack.isEmpty()) {
            uint i = stack.pop();
            if(flags[i] == Flag.UNKNOWN) {
                flags[i] = Flag.OUTSIDE;

                uint z = i / Z;
                uint y = (i % Z) / Y;
                uint x = i % Y;

                if(x > 0 && flags[i-X] == Flag.UNKNOWN) {
                    stack.push(i - X);
                }
                if(x < size.x-1 && flags[i+X] == Flag.UNKNOWN) {
                    stack.push(i + X);
                }
                if(y > 0 && flags[i-Y] == Flag.UNKNOWN) {
                    stack.push(i - Y);
                }
                if(y < size.y-1 && flags[i+Y] == Flag.UNKNOWN) {
                    stack.push(i + Y);
                }
                if(z > 0 && flags[i-Z] == Flag.UNKNOWN) {
                    stack.push(i - Z);
                }
                if(z < size.z-1 && flags[i+Z] == Flag.UNKNOWN) {
                    stack.push(i + Z);
                }
            }
        }

        // We have now marked all cells that are definitely outside of the object. 
        // All UNKNOWN cells must be inside the object.
        uint numInteriorVoxels;
        foreach(i; 0..flags.length) {
            if(flags[i] == Flag.UNKNOWN) {
                // For now just make them 1. A possible improvement would be to take the colour from 
                // an adjacent solid cell if there is one. This would mean several iterations where we
                // fill in UNKNOWN cells that are adjacent to SOLID cells recursively.
                voxels[i] = 1;
                numInteriorVoxels++;
            }
        }
        writefln("numInteriorVoxels = %s (%.2f %%)", numInteriorVoxels, (numInteriorVoxels.as!double/voxels.length.as!float)*100);
    }
}
