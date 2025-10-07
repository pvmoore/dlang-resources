module resources.models.wavefront.Obj;

import resources.all;

/**
 * Wavefront OBJ file loader.
 *
 * https://en.wikipedia.org/wiki/Wavefront_.obj_file
 */
final class Obj : ModelData {
public:
    static Obj read(string filename) {
        string data = From!"std.file".read(filename).as!string;

        auto model = new Obj();
        string[] tokens;

        void _addVertex() {
            model.vertices ~= float3(tokens[1].to!float, tokens[2].to!float * 1f, tokens[3].to!float);
        }
        void _addNormal() {
            model.normals ~= float3(tokens[1].to!float, tokens[2].to!float, tokens[3].to!float);
        }
        void _addUV() {
            model.uvs ~= float2(tokens[1].to!float, tokens[2].to!float);
        }
        /**
         * f  v1/uv1/n1  v2/uv2/n2  v3/uv3/n3   -> supported
         * f  v1/uv1     v2/uv2     v3/uv3      -> todo
         * f  v1//n1     v2//n2     v3//n3      -> supported
         * f  v1         v2         v3          -> todo
         */
        void _addFace() {
            auto parts = tokens[1].split("/");
            switch(parts.length) {
                case 3:
                    Face f;

                    // v1
                    f.iVertices[0] = parts[0].to!int-1;
                    f.iUvs[0]      = parts[1].length!=0 ? parts[1].to!int-1 : -1;
                    f.iNormals[0]  = parts[2].to!int-1;
                    f.colours[0]   = float4(1f, 0.7f, 0.2f, 1f);

                    // v2
                    parts = tokens[2].split("/");
                    f.iVertices[1] = parts[0].to!int-1;
                    f.iUvs[1]      = parts[1].length!=0 ? parts[1].to!int-1 : -1;
                    f.iNormals[1]  = parts[2].to!int-1;
                    f.colours[1]   = float4(1f, 0.7f, 0.2f, 1f);

                    // v3
                    parts = tokens[3].split("/");
                    f.iVertices[2] = parts[0].to!int-1;
                    f.iUvs[2]      = parts[1].length!=0 ? parts[1].to!int-1 : -1;
                    f.iNormals[2]  = parts[2].to!int-1;
                    f.colours[2]   = float4(1f, 0.7f, 0.2f, 1f);

                    model.faces ~= f;
                    break;
                default:
                    throw new Error("Handle parts = %s".format(parts.length));
            }
        }

        foreach(line; splitLines(data)) {
            line = line.strip();
            if(line.length==0 || line[0] == '#') continue;

            tokens = line.split();

            switch(tokens[0]) {
                case "v": _addVertex(); break;
                case "f": _addFace(); break;
                case "vt": _addUV(); break;
                case "vn": _addNormal(); break;
                case "usemtl": /* material */ break;
                case "s": /* smooth shading */ break;
                case "o": /* object name */ break;
                case "g": /* group name */ break;
                default:
                    throw new Error("Bad OBJ file: " ~ tokens[0]);
            }
        }

        chat("vertices: %s", model.vertices.length);
        chat("normals:  %s", model.normals.length);
        chat("uvs:      %s", model.uvs.length);
        chat("faces:    %s", model.faces.length);

        return model;
    }
private:

}
