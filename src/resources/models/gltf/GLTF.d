module resources.models.gltf.GLTF;

/**
 * https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#glb-file-format-specification-structure
 *
 *
 */
import resources.all;
private {
    import resources.models.gltf.glb_reader;
    import resources.models.gltf.gltf_common;
    import resources.models.gltf.gltf_reader;
}

final class GLTF {
public:
    string filename; 

    Nullable!uint scene;
    Accessor[] accessors;
    Animation[] animations;
    Asset asset;
    Buffer[] buffers;
    BufferView[] bufferViews;
    Camera[] cameras;
    Extensions extensions;
    Image_[] images;
    Material[] materials;
    Mesh[] meshes;
    Node[] nodes;
    Sampler[] samplers;
    Scene[] scenes;
    Skin[] skins;
    Texture[] textures;
    string[] extensionsUsed;
    string[] extensionsRequired;
    ubyte[] binaryChunkData;

    static GLTF read(string filename) {

        GLTF gltf = new GLTF();
        gltf.filename = filename;

        string ext = filename.extension().toLower();

        if(ext == ".glb") {
            readBinaryGLTF(gltf);
        } else if(ext == ".gltf") {
            readJsonGLTF(gltf);
        } else {
            throwIf(true, "Unsupported GLTF file extension: %s", ext);
        }

        fetchBufferData(gltf);

        return gltf;
    }
    
}
