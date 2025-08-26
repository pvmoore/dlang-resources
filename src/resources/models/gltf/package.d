module resources.models.gltf;

private import resources.all;

public:
import resources.models.gltf.GLTF;
import resources.models.gltf.gltf_common;

private {
    IndexData NO_INDEX_DATA = IndexData();
    AttributeData NO_ATTRIBUTE_DATA = AttributeData();
}

struct IndexData {
    uint accessorIndex;
    uint stride;
    ubyte[] data;

    bool hasData() { return data.length > 0; }
    uint count() { return data.length.as!uint / stride; }

    string toString() {
        return "IndexData(data: %s, stride: %s)".format(data.length, stride);
    }
}

IndexData getIndices(GLTF gltf, uint meshIndex, uint primitivesIndex) 
in {
    throwIf(gltf.meshes.length <= meshIndex, "Mesh %s not found", meshIndex);
    throwIf(gltf.meshes[meshIndex].primitives.length <= primitivesIndex, "MeshPrimitive %s not found", primitivesIndex);
}
do{
    return getIndices(gltf, gltf.meshes[meshIndex].primitives[primitivesIndex]);
}
IndexData getIndices(GLTF gltf, MeshPrimitive primitive) {
    if(primitive.indices.isNull()) return NO_INDEX_DATA;

    uint accessorIndex = primitive.indices.get();
    auto accessor = gltf.accessors[accessorIndex];
    throwIf(accessor.type != Accessor.Type.SCALAR, "Unsupported index type %s", accessor.type);

    uint stride = 2;
    if(accessor.componentType == Accessor.ComponentType.UNSIGNED_INT) {
        stride = 4;
    }

    ubyte[] data = getBufferViewData(gltf, accessor.bufferView.get(), accessor.byteOffset, accessor.count * stride);

    return IndexData(accessorIndex, stride, data);
}

struct AttributeData {
    uint accessorIndex;
    uint stride;
    uint componentStride;
    ubyte[] data;

    bool hasData() { return data.length > 0; }

    string toString() {
        return "DataAndStride(data: %s, stride: %s, componentStride: %s)".format(
            data.length, stride, componentStride
        );
    }
}

AttributeData getAttributeData(GLTF gltf, uint meshIndex, uint primitivesIndex, string attribute) {
    if(meshIndex >= gltf.meshes.length) return NO_ATTRIBUTE_DATA;
    Mesh mesh = gltf.meshes[meshIndex];
    if(primitivesIndex >= mesh.primitives.length) return NO_ATTRIBUTE_DATA;
    MeshPrimitive primitive = mesh.primitives[primitivesIndex];

    return getAttributeData(gltf, primitive, attribute);
}
AttributeData getAttributeData(GLTF gltf, MeshPrimitive primitive, string attribute) {
    if(primitive.hasAttribute(attribute)) {
        uint accessorIndex = primitive.attributes[attribute];
        Accessor accessor = gltf.accessors[accessorIndex];
        uint viewIndex = accessor.bufferView.get();
        uint offset = accessor.byteOffset;
        uint count = accessor.count;
        uint stride = accessor.stride();

        ubyte[] data = getBufferViewData(gltf, viewIndex, offset, count * stride);

        return AttributeData(accessorIndex, stride, accessor.componentStride(), data);
    }

    return NO_ATTRIBUTE_DATA;
}

ubyte[] getBufferData(GLTF gltf, uint bufferIndex, uint byteOffset, uint numBytes) 
in {
    throwIf(gltf.buffers.length <= bufferIndex, "Buffer %s not found", bufferIndex);
} do {
    Buffer buffer = gltf.buffers[bufferIndex];
    return buffer.data[byteOffset..byteOffset+numBytes];
}

ubyte[] getBufferViewData(GLTF gltf, uint bufferViewIndex, uint byteOffset, uint numBytes) 
in {
    throwIf(gltf.bufferViews.length <= bufferViewIndex, "Buffer view %s not found", bufferViewIndex);    
} do {
    BufferView view = gltf.bufferViews[bufferViewIndex];
    return getBufferData(gltf, view.buffer, byteOffset + view.byteOffset, numBytes);
}
