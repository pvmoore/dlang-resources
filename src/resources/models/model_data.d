module resources.models.model_data;

import resources.all;

abstract class ModelData {
public:
    struct Face {
        int[3] iVertices;
        int[3] iUvs;
        int[3] iNormals;
        float4[3] colours;

        bool hasNormals() { return iNormals[0] != -1; }
        bool hasUvs() { return iUvs[0] != -1; }
    }

    float3[] vertices;
    float3[] normals;
    float2[] uvs;
    Face[] faces;

    float3 vertex(ref Face f, uint i) { return vertices[f.iVertices[i]]; }
    float3 normal(ref Face f, uint i) { return normals[f.iNormals[i]]; }
    float2 uv(ref Face f, uint i) { return uvs[f.iUvs[i]]; }
    float4 colour(ref Face f, uint i) { return f.colours[i]; }
}