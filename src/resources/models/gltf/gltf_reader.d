module resources.models.gltf.gltf_reader;

/**
 * https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#appendix-a-json-schema-reference
 */
import resources.all;
private import resources.models.gltf;

uint[] _uintArray(J5Array array) {
    uint[] result;
    foreach(v; array) {
        result ~= v.as!J5Number.getInt();
    }
    return result;
}
float[] _floatArray(J5Array array) {
    float[] result;
    foreach(v; array) {
        result ~= v.as!J5Number.getFloat();
    }
    return result;
}
string[] _stringArray(J5Array array) {
    string[] result;
    foreach(v; array) {
        result ~= v.toString();
    }
    return result;
}
string[string] _map(J5Object o) {
    string[string] result;
    foreach(k,v; o) {
        result[k] = v.toString();
    }
    return result;
}

Animation[] _animations(J5Array array) {
    Animation[] animations;
    foreach(a; array) {
        Animation animation;

        foreach(k,v; a.as!J5Object) {
            switch(k) {
                case "name": animation.name = v.toString(); break;
                case "channels": animation.channels = _animationChannels(v.as!J5Array); break;
                case "samplers": animation.samplers = _animationSamplers(v.as!J5Array); break;
                default: throwIf(true, "Unhandled animation key: %s", k);
            }
        }
        animations ~= animation;
    }
    return animations;
}
AnimationChannel[] _animationChannels(J5Array array) {
    AnimationChannel[] channels;
    foreach(a; array) {
        AnimationChannel ac;
        foreach(k,v; a.as!J5Object) {
            switch(k) {
                case "sampler": ac.sampler = v.as!J5Number.getInt(); break;
                case "target": ac.target = _animationChannelTarget(v.as!J5Object); break;
                default: throwIf(true, "Unhandled animationChannel key: %s", k);
            }
        }
        channels ~= ac;
    }
    return channels;
}
AnimationChannelTarget _animationChannelTarget(J5Object o) {
    AnimationChannelTarget act;
    foreach(k,v; o) {
        switch(k) {
            case "node": act.node = v.as!J5Number.getInt(); break;
            case "path": act.path = v.toString().to!(AnimationChannelTarget.Path); break;
            default: throwIf(true, "Unhandled animationChannelTarget key: %s", k);
        }
    }
    return act;
}
AnimationSampler[] _animationSamplers(J5Array array) {
    AnimationSampler[] samplers;
    foreach(a; array) {
        AnimationSampler as;
        foreach(k,v; a.as!J5Object) {
            switch(k) {
                case "input": as.input = v.as!J5Number.getInt(); break;
                case "output": as.output = v.as!J5Number.getInt(); break;
                case "interpolation": as.interpolation = v.toString().to!(AnimationSampler.Interpolation); break;
                default: throwIf(true, "Unhandled animationSampler key: %s", k);
            }
        }
        samplers ~= as;
    }
    return samplers;
}

CameraOrthographic _cameraOrthographic(J5Object o) {
    CameraOrthographic co;
    foreach(k,v; o) {
        switch(k) {
            case "xmag": co.xmag = v.as!J5Number.getFloat(); break;
            case "ymag": co.ymag = v.as!J5Number.getFloat(); break;
            case "zfar": co.zfar = v.as!J5Number.getFloat(); break;
            case "znear": co.znear = v.as!J5Number.getFloat(); break;
            default: throwIf(true, "Unhandled cameraOrthographic key: %s", k);
        }
    }
    return co;
}
CameraPerspective _cameraPerspective(J5Object o) {
    CameraPerspective cp;
    foreach(k,v; o) {
        switch(k) {
            case "aspectRatio": cp.aspectRatio = v.as!J5Number.getFloat(); break;
            case "yfov": cp.yfov = v.as!J5Number.getFloat(); break;
            case "zfar": cp.zfar = v.as!J5Number.getFloat(); break;
            case "znear": cp.znear = v.as!J5Number.getFloat(); break;
            default: throwIf(true, "Unhandled cameraPerspective key: %s", k);
        }
    }
    return cp;
}
OcculusionTextureInfo _occulusionTextureInfo(J5Object o) {
    OcculusionTextureInfo oti;
    foreach(k,v; o) {
        switch(k) {
            case "index": oti.index = v.as!J5Number.getInt(); break;
            case "texCoord": oti.texCoord = v.as!J5Number.getInt(); break;
            case "strength": oti.strength = v.as!J5Number.getFloat(); break;
            default: throwIf(true, "Unhandled occulusionTextureInfo key: %s", k);
        }
    }
    return oti;
}
Extensions _extensions(J5Object o) {
    Extensions e;
    foreach(k,v; o) {
        e.properties[k] = _map(v.as!J5Object);
    }
    return e;
}
TextureInfo _textureInfo(J5Object o) {
    TextureInfo ti;
    foreach(k,v; o) {
        switch(k) {
            case "index": ti.index = v.as!J5Number.getInt(); break;
            case "texCoord": ti.texCoord = v.as!J5Number.getInt(); break;
            default: throwIf(true, "Unhandled textureInfo key: %s", k);
        }
    }
    return ti;
}
NormalTextureInfo _normalTextureInfo(J5Object o) {
    NormalTextureInfo nti;
    foreach(k,v; o) {
        switch(k) {
            case "index": nti.index = v.as!J5Number.getInt(); break;
            case "texCoord": nti.texCoord = v.as!J5Number.getInt(); break;
            case "scale": nti.scale = v.as!J5Number.getFloat(); break;
            default: throwIf(true, "Unhandled normalTextureInfo key: %s", k);
        }
    }
    return nti;
}
MaterialPBRMetalicRoughness _pbrMetallicRoughness(J5Object o) {
    MaterialPBRMetalicRoughness pbr;
    foreach(k,v; o) {
        switch(k) {
            case "baseColorFactor": pbr.baseColorFactor = _floatArray(v.as!J5Array); break;
            case "metallicFactor": pbr.metallicFactor = v.as!J5Number.getFloat(); break;
            case "roughnessFactor": pbr.roughnessFactor = v.as!J5Number.getFloat(); break;
            case "baseColorTexture": pbr.baseColorTexture = _textureInfo(v.as!J5Object); break;
            case "metallicRoughnessTexture": pbr.metallicRoughnessTexture = _textureInfo(v.as!J5Object); break;
            default: throwIf(true, "Unhandled pbrMetallicRoughness key: %s", k);
        }
    }
    return pbr;
}

Accessor[] _accessors(J5Array array) {
    Accessor[] accessors;
    foreach(a; array) {
        Accessor accessor;

        foreach(k,v; a.as!J5Object) {
            switch(k) {
                case "bufferView": accessor.bufferView = v.as!J5Number.getInt(); break;
                case "byteOffset": accessor.byteOffset = v.as!J5Number.getInt(); break;
                case "componentType": accessor.componentType = v.as!J5Number.getInt().to!(Accessor.ComponentType); break;
                case "normalized": accessor.normalized = v.as!J5Boolean.value; break;
                case "count": accessor.count = v.as!J5Number.getInt(); break;
                case "type": accessor.type = v.toString().to!(Accessor.Type); break;
                case "max": accessor.maxValues = _floatArray(v.as!J5Array); break;
                case "min": accessor.minValues = _floatArray(v.as!J5Array); break;
                case "sparse":
                    throwIf(true, "Handle sparse accessors");
                    break;
                default: throwIf(true, "Unhandled accessor key: %s", k);
            }
        }
        accessors ~= accessor;
    }
    return accessors;
}
Asset _asset(J5Object o) {
    Asset asset;
    foreach(k, v; o) {
        switch(k) {
            case "copyright": asset.copyright = v.toString(); break;
            case "generator": asset.generator = v.toString(); break;
            case "version": asset.version_ = v.toString(); break;
            case "minVersion": asset.minVersion = v.toString(); break;
            case "extras": asset.extras = _map(v.as!J5Object); break;
            default: throwIf(true, "Unhandled asset key: %s", k);
        }
    }
    return asset;
}
Buffer[] _buffers(J5Array array) {
    Buffer[] buffers;
    foreach(b; array) {
        Buffer buffer;
        foreach(k,v; b.as!J5Object) {
            switch(k) {
                case "name": buffer.name = v.toString(); break;
                case "byteLength": buffer.byteLength = v.as!J5Number.getInt(); break;
                case "uri": buffer.uri = v.toString(); break;
                case "extensions": buffer.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled buffer key: %s", k);
            }
        }
        buffers ~= buffer;
    }
    return buffers;
}
BufferView[] _bufferViews(J5Array array) {
    BufferView[] bufferViews;
    foreach(bv; array) {
        BufferView view;

        foreach(k,v; bv.as!J5Object) {
            switch(k) {
                case "name": view.name = v.toString(); break;
                case "buffer": view.buffer = v.as!J5Number.getInt(); break;
                case "byteOffset": view.byteOffset = v.as!J5Number.getInt(); break;
                case "byteLength": view.byteLength = v.as!J5Number.getInt(); break;
                case "byteStride": view.byteStride = v.as!J5Number.getInt(); break;
                case "target": view.target = v.as!J5Number.getInt(); break;
                case "extensions": view.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled bufferView key: %s", k);
            }
        }
        bufferViews ~= view;
    }
    return bufferViews;
}
Camera[] _cameras(J5Array array) {
    Camera[] cameras;
    foreach(c; array) {
        Camera camera;

        foreach(k,v; c.as!J5Object) {
            switch(k) {
                case "name": camera.name = v.toString(); break;
                case "type": camera.type = v.toString().to!(Camera.Type); break;
                case "orthographic": camera.orthographic = _cameraOrthographic(v.as!J5Object); break;
                case "perspective": camera.perspective = _cameraPerspective(v.as!J5Object); break;
                case "extras": camera.extras = _map(v.as!J5Object); break;
                case "extensions": camera.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled camera key: %s", k);
            }
        }
        cameras ~= camera;
    }
    return cameras;
}
Image_[] _images(J5Array array) {
    import std.uri : decode;

    Image_[] images;
    foreach(i; array) {
        Image_ image;
        
        foreach(k,v; i.as!J5Object) {
            switch(k) {
                case "name": image.name = v.toString(); break;
                case "uri": image.uri = decode(v.toString()); break;
                case "mimeType": image.mimeType = v.toString(); break;
                case "bufferView": image.bufferView = v.as!J5Number.getInt(); break;
                default: throwIf(true, "Unhandled image key: %s", k);
            }
        }
        images ~= image;
    }
    return images;
}
Material[] _materials(J5Array array) {
    Material[] materials;
    foreach(m; array) {
        Material material;

        foreach(k,v; m.as!J5Object) {
            switch(k) {
                case "name": material.name = v.toString(); break;
                case "pbrMetallicRoughness": material.pbrMetallicRoughness = _pbrMetallicRoughness(v.as!J5Object); break;
                case "normalTexture": material.normalTexture = _normalTextureInfo(v.as!J5Object); break;
                case "occlusionTexture": material.occlusionTexture = _occulusionTextureInfo(v.as!J5Object); break;
                case "emissiveTexture": material.emissiveTexture = _textureInfo(v.as!J5Object); break;
                case "emissiveFactor": material.emissiveFactor = _floatArray(v.as!J5Array); break;
                case "alphaMode": material.alphaMode = v.toString().to!(Material.AlphaMode); break;
                case "alphaCutoff": material.alphaCutoff = v.as!J5Number.getFloat(); break;
                case "doubleSided": material.doubleSided = v.as!J5Boolean.value; break;
                case "extensions": material.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled material key: %s", k);
            }
        }
        materials ~= material;
    }
    return materials;
}
Mesh[] _meshes(J5Array array) {
    Mesh[] meshes;
    foreach(m; array) {
        Mesh mesh;

        foreach(k,v; m.as!J5Object) {
            switch(k) {
                case "name": mesh.name = v.toString(); break;
                case "primitives": {
                    foreach(p; v.as!J5Array) {
                        MeshPrimitive primitive;

                        foreach(k2,v2; p.as!J5Object) {
                            switch(k2) {
                                case "attributes": {
                                    auto attributes = v2.as!J5Object;
                                    foreach(k3,v3; attributes) {
                                        primitive.attributes[k3] = v3.as!J5Number.getInt();
                                    }
                                    break;
                                }
                                case "indices": primitive.indices = v2.as!J5Number.getInt(); break;
                                case "material": primitive.material = v2.as!J5Number.getInt(); break;
                                case "mode": primitive.mode = v2.as!J5Number.getInt().to!(MeshPrimitive.Mode); break;
                                default: throwIf(true, "Unhandled mesh primitive key: %s", k2);
                            }
                        }
                        mesh.primitives ~= primitive;
                    }
                    break;
                }
                default: throwIf(true, "Unhandled mesh key: %s", k);
            }
        }
        meshes ~= mesh;
    }
    return meshes;
}
Node[] _nodes(J5Array array) {
    Node[] nodes;
    foreach(n; array) {
        Node node;

        foreach(k,v; n.as!J5Object) {
            switch(k) {
                case "camera": node.camera = v.as!J5Number.getInt(); break;
                case "mesh": node.mesh = v.as!J5Number.getInt(); break;
                case "children": node.children = _uintArray(v.as!J5Array); break;
                case "matrix": node.matrix = _floatArray(v.as!J5Array); break;
                case "rotation": node.rotation = _floatArray(v.as!J5Array); break;
                case "scale": node.scale = _floatArray(v.as!J5Array); break;
                case "skin": node.skin = v.as!J5Number.getInt(); break;
                case "translation": node.translation = _floatArray(v.as!J5Array); break;
                case "weights": node.weights = _uintArray(v.as!J5Array); break;
                case "name": node.name = v.toString(); break;
                case "extras": node.extras = _map(v.as!J5Object); break;
                case "extensions": node.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled node key: %s", k);
            }
        }
        nodes ~= node;
    }
    return nodes;
}
Scene[] _scenes(J5Array array) {
    Scene[] scenes;
    foreach(s; array) {
        Scene scene;

        foreach(k,v; s.as!J5Object) {
            switch(k) {
                case "name": scene.name = v.toString(); break;
                case "nodes": scene.nodes = _uintArray(v.as!J5Array); break;
                case "extras": scene.extras = _map(v.as!J5Object); break;
                case "extensions": scene.extensions = _extensions(v.as!J5Object); break;
                default: throwIf(true, "Unhandled scene key: %s", k);
            }
        }
        scenes ~= scene;
    }
    return scenes;
}
Sampler[] _samplers(J5Array array) {
    Sampler[] samplers;
    foreach(s; array) {
        Sampler sampler;

        foreach(k,v; s.as!J5Object) {
            switch(k) {
                case "magFilter": sampler.magFilter = v.as!J5Number.getInt().to!(Sampler.Filter); break;
                case "minFilter": sampler.minFilter = v.as!J5Number.getInt().to!(Sampler.Filter); break;
                case "wrapS": sampler.wrapS = v.as!J5Number.getInt().to!(Sampler.Wrap); break;
                case "wrapT": sampler.wrapT = v.as!J5Number.getInt().to!(Sampler.Wrap); break;
                default: throwIf(true, "Unhandled sampler key: %s", k);
            }
        }
        samplers ~= sampler;
    }
    return samplers;
}
Skin[] _skins(J5Array array) {
    Skin[] skins;
    foreach(s; array) {
        Skin skin;

        foreach(k,v; s.as!J5Object) {
            switch(k) {
                case "name": skin.name = v.toString(); break;
                case "inverseBindMatrices": skin.inverseBindMatrices = v.as!J5Number.getInt(); break;
                case "skeleton": skin.skeleton = v.as!J5Number.getInt(); break;
                case "joints": skin.joints = _uintArray(v.as!J5Array); break;
                default: throwIf(true, "Unhandled skin key: %s", k);
            }
        }
        skins ~= skin;
    }
    return skins;
}
Texture[] _textures(J5Array array) {
    Texture[] textures;
    foreach(a; array) {
        Texture t;

        foreach(k,v; a.as!J5Object) {
            switch(k) {
                case "sampler": t.sampler = v.as!J5Number.getInt(); break;
                case "source": t.source = v.as!J5Number.getInt(); break;
                case "name": t.name = v.toString(); break;
                case "extras": t.extras = _map(v.as!J5Object); break;
                default: throwIf(true, "Unhandled texture key: %s", k);
            }
        }
        textures ~= t;
    }
    return textures;
}

void readJsonGLTF(GLTF gltf) {
    import std.file : read;

    chat("Reading GLTF json '%s'", gltf.filename);
    string jsonString = read(gltf.filename).as!string;
    readJsonGLTF(gltf, jsonString);
}

// This can also be called from readBinaryGLTF to process the JSON chunk
void readJsonGLTF(GLTF gltf, string jsonString) {
    auto j = JSON5.fromString(jsonString);

    foreach(k, v; j.as!J5Object) {
        //chat("key: %s", k);
        switch(k) {
            case "accessors": gltf.accessors = _accessors(v.as!J5Array); break;
            case "animations": gltf.animations = _animations(v.as!J5Array); break;
            case "asset": gltf.asset = _asset(v.as!J5Object); break;
            case "buffers": gltf.buffers = _buffers(v.as!J5Array); break;
            case "bufferViews": gltf.bufferViews = _bufferViews(v.as!J5Array); break;
            case "cameras": gltf.cameras = _cameras(v.as!J5Array); break;
            case "extensions": gltf.extensions = _extensions(v.as!J5Object); break;
            case "extensionsRequired": gltf.extensionsRequired = _stringArray(v.as!J5Array); break;
            case "extensionsUsed": gltf.extensionsUsed = _stringArray(v.as!J5Array); break;
            case "images": gltf.images = _images(v.as!J5Array); break;
            case "materials": gltf.materials = _materials(v.as!J5Array); break;
            case "meshes": gltf.meshes = _meshes(v.as!J5Array); break;
            case "nodes": gltf.nodes = _nodes(v.as!J5Array); break;
            case "samplers": gltf.samplers = _samplers(v.as!J5Array); break;
            case "scene": gltf.scene = v.as!J5Number.getInt(); break;
            case "scenes": gltf.scenes = _scenes(v.as!J5Array); break;
            case "skins": gltf.skins = _skins(v.as!J5Array); break;
            case "textures": gltf.textures = _textures(v.as!J5Array); break;
            default: throwIf(true, "Unhandled key: %s", k);
        }
        //chat("key: %s done", k);
    }
}
