module resources.models.gltf.gltf_common;

import resources.all;

private {
    import resources.models.gltf;
    import resources.models.gltf.meshopt.meshopt;
}

struct Accessor {
    enum ComponentType {
        BYTE            = 5120,
        UNSIGNED_BYTE   = 5121,
        SHORT           = 5122,
        UNSIGNED_SHORT  = 5123,
        UNSIGNED_INT    = 5125,
        FLOAT           = 5126
    }
    enum Type : string {
        SCALAR  = "SCALAR",
        VEC2    = "VEC2", 
        VEC3    = "VEC3",
        VEC4    = "VEC4",
        MAT2    = "MAT2",
        MAT3    = "MAT3",
        MAT4    = "MAT4"
    }
    string name;
    Nullable!uint bufferView;
    uint byteOffset = 0;
    ComponentType componentType;
    bool normalized = false;
    uint count;
    Type type;
    float[] maxValues;  // 0..16 values
    float[] minValues;  // 0..16 values

    bool isScalarFloat() { return type == Type.SCALAR && componentType == ComponentType.FLOAT; }
    bool isFloat2() { return type == Type.VEC2 && componentType == ComponentType.FLOAT; }
    bool isFloat3() { return type == Type.VEC3 && componentType == ComponentType.FLOAT; }
    bool isFloat4() { return type == Type.VEC4 && componentType == ComponentType.FLOAT; }
    bool isFloatMat2() { return type == Type.MAT2 && componentType == ComponentType.FLOAT; }
    bool isFloatMat3() { return type == Type.MAT3 && componentType == ComponentType.FLOAT; }
    bool isFloatMat4() { return type == Type.MAT4 && componentType == ComponentType.FLOAT; }

    uint componentStride() {
        final switch(componentType) {
            case ComponentType.BYTE:            
            case ComponentType.UNSIGNED_BYTE:   return 1;
            case ComponentType.SHORT:           
            case ComponentType.UNSIGNED_SHORT:  return 2;
            case ComponentType.UNSIGNED_INT:   
            case ComponentType.FLOAT:           return 4;
        }
    }
    uint stride() { 
        uint i;
        final switch(type) {
            case Type.SCALAR:  i = 1; break;
            case Type.VEC2:    i = 2; break;
            case Type.VEC3:    i = 3; break;
            case Type.VEC4:    i = 4; break;
            case Type.MAT2:    i = 4; break;
            case Type.MAT3:    i = 9; break;
            case Type.MAT4:    i = 16; break;
        }
        return i * componentStride();
    }
}
struct Animation {
    string name;
    AnimationChannel[] channels;
    AnimationSampler[] samplers;
}
struct AnimationChannel {
    uint sampler;                   // The index of a sampler in this animation used to compute the value for the target
    AnimationChannelTarget target;
}
struct AnimationChannelTarget {
    enum Path {
        translation,
        rotation,
        scale,
        weights
    }
    uint node; // The index of the node to animate 
    Path path;
}
struct AnimationSampler {
    enum Interpolation { LINEAR, STEP, CUBICSPLINE }
    uint input;             // index of an accessor containing keyframe timestamps
    uint output;            // index of an accessor, containing keyframe output values
    Interpolation interpolation = Interpolation.LINEAR;
}
struct Asset {
    string copyright;
    string generator;
    string version_;
    string minVersion;
    string[string] extras;
}
struct Buffer {
    string name;
    ulong byteLength;
    string uri;
    ubyte[] data;
    Extensions extensions;

    string toString() {
        string u = uri.length > 20 ? uri[0..20] ~ "..." : uri;
        return "Buffer(%s bytes, %s)".format(byteLength, u);
    }
}
struct BufferView {
    string name;
    uint buffer; 
    uint byteOffset = 0;
    Nullable!uint byteLength;
    Nullable!uint byteStride;
    Nullable!uint target;
    Extensions extensions;
}
struct Camera {
    enum Type {
        perspective,
        orthographic
    }
    string name;
    Type type;
    union {
        CameraOrthographic orthographic;
        CameraPerspective perspective;
    }
    string[string] extras;
    Extensions extensions;
}
struct CameraOrthographic {
    float xmag;
    float ymag;
    float zfar;
    float znear;
}
struct CameraPerspective {
    float aspectRatio;
    float yfov;
    float zfar;
    float znear;
}
struct Extensions {
    string[string][string] properties;
}
struct Image_ {
    string name;
    string uri;
    string mimeType;
    uint bufferView;
}
struct Material {
    enum AlphaMode {
        OPAQUE,
        MASK,
        BLEND
    }
    string name;
    Nullable!MaterialPBRMetalicRoughness pbrMetallicRoughness;
    Nullable!NormalTextureInfo normalTexture;
    Nullable!OcculusionTextureInfo occlusionTexture;
    Nullable!TextureInfo emissiveTexture;
    float[] emissiveFactor = [ 0.0, 0.0, 0.0 ];
    AlphaMode alphaMode = AlphaMode.OPAQUE;
    float alphaCutoff = 0.5;
    bool doubleSided = false;
    Extensions extensions;
    string[string] extras;
}
struct MaterialPBRMetalicRoughness {
    float[] baseColorFactor = [ 1.0, 1.0, 1.0, 1.0 ];
    float metallicFactor = 1.0;
    float roughnessFactor = 1.0;
    Nullable!TextureInfo baseColorTexture;
    Nullable!TextureInfo metallicRoughnessTexture;
}
struct Mesh {
    string name;
    MeshPrimitive[] primitives;
}
struct MeshPrimitive {
    enum Mode {
        POINTS          = 0,
        LINES           = 1,
        LINE_LOOP       = 2,
        LINE_STRIP      = 3,
        TRIANGLES       = 4,
        TRIANGLE_STRIP  = 5,
        TRIANGLE_FAN    = 6
    }
    enum Semantic : string {
        POSITION   = "POSITION",
        NORMAL     = "NORMAL",
        TANGENT    = "TANGENT",
        TEXCOORD_0 = "TEXCOORD_0",

        // ... add more as needed
    }
    uint[string] attributes;      // <semantic-name> to accessor index
    Nullable!uint indices;          // accessor index
    Nullable!uint material;         // material index
    Mode mode = Mode.TRIANGLES;
    Extensions extensions;

    bool hasAttribute(string attr) {
        return (attr in attributes) !is null;
    }
}
struct Node {
    string name;
    uint[] children;
    Nullable!uint camera;   
    Nullable!uint skin;  
    float[16] matrix     = [ 1.0, 0.0, 0.0, 0.0, 
                             0.0, 1.0, 0.0, 0.0, 
                             0.0, 0.0, 1.0, 0.0, 
                             0.0, 0.0, 0.0, 1.0 ];
    Nullable!uint mesh;       
    float[4] rotation    = [ 0.0, 0.0, 0.0, 1.0 ];
    float[3] scale       = [ 1.0, 1.0, 1.0 ];
    float[3] translation = [ 0.0, 0.0, 0.0 ];
    uint[] weights;
    string[string] extras;
    Extensions extensions;
}
struct NormalTextureInfo {
    uint index;
    uint texCoord;
    float scale = 1.0;
    Extensions extensions;
}
struct OcculusionTextureInfo {
    uint index;
    uint texCoord;
    float strength = 1.0;
    Extensions extensions;
}
struct Sampler {
    enum Filter {
        NEAREST = 9728,
        LINEAR = 9729,
        NEAREST_MIPMAP_NEAREST = 9984,
        LINEAR_MIPMAP_NEAREST = 9985,
        NEAREST_MIPMAP_LINEAR = 9986,
        LINEAR_MIPMAP_LINEAR = 9987
    }
    enum Wrap {
        CLAMP_TO_EDGE = 33071,
        MIRRORED_REPEAT = 33648,
        REPEAT = 10497
    }
    Filter magFilter;
    Filter minFilter;
    Wrap wrapS;
    Wrap wrapT;
}
struct Scene {
    string name;
    uint[] nodes;
    string[string] extras;
    Extensions extensions;
}
struct Skin {
    string name;
    Nullable!uint inverseBindMatrices;
    uint skeleton;
    uint[] joints;
}
struct Texture {
    uint sampler;
    uint source;
    string name;
    string[string] extras;
}
struct TextureInfo {
    uint index;
    uint texCoord;
    Extensions extensions;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
package:

void fetchBufferData(GLTF gltf) {
    foreach(i, ref buffer; gltf.buffers) {
        uint bufferIndex = i.as!uint;

        if(buffer.uri is null) {
            // The data must be in gltf.binaryChunkData

            // If this is the first Buffer in the list then assert that binaryChunkData contains all the data
            // plus an optional 1 to 3 bytes padding at the end (to align to 4 bytes) 
            if(bufferIndex == 0) {
                throwIf(gltf.binaryChunkData.length < buffer.byteLength, "BIN chunk data is too small");

                // Copy the data to Buffer
                buffer.data = gltf.binaryChunkData[0..buffer.byteLength].dup;
                continue;
            }

            // Any glTF buffer with undefined buffer.uri property that is not the first element of buffers 
            // array does not refer to the GLB-stored BIN chunk, and the behavior of such buffers is left 
            // undefined to accommodate future extensions and specification versions

        } else if(buffer.uri.startsWith("data:application/octet-stream;base64,")) {
            // embedded base64 data 
            import std.base64;

            buffer.data.length = buffer.byteLength;
            auto decoded = Base64.decode(buffer.uri[37..$], buffer.data);
            throwIf(buffer.byteLength!=decoded.length, "Base64 decoded length mismatch");

        } else {
            // assume this is a relative file reference

            import std.path : buildPath, dirName;

            string p = buildPath(dirName(gltf.filename), buffer.uri);
            // chat("filename = %s", gltf.filename);
            // chat("base     = %s", dirName(gltf.filename));
            // chat("uri      = %s", buffer.uri);
            // chat("p        = %s", p);

            if(!exists(p)) {
                throw new Exception("Unable to find buffer file: %s".format(buffer.uri));
            }
            if(getSize(p) != buffer.byteLength) {
                throw new Exception("Buffer file size should be %s but is %s".format(buffer.byteLength, getSize(buffer.uri)));
            }

            import std.file : read;
            buffer.data = read(p).as!(ubyte[]);
        }
    }
    // Clear the binary chunk data as it is no longer needed
    gltf.binaryChunkData = null;

    // Iterate thought the BufferViews and decode the data
    foreach(view; gltf.bufferViews) {
        if(auto props = view.extensions.properties.get("EXT_meshopt_compression", null)) {
            decodeMeshopt(gltf, view, props);
        }
    }
}
