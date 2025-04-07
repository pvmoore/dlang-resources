module resources.code.DLL;

/**
 *  https://en.wikipedia.org/wiki/Dynamic-link_library
 *
 *
 */
import resources.all;
import std.stdio;
import std.file;

final class DLL {
public:
    this(string filename) {
        this.filename = filename;
    }

    void read() {
        data = cast(ubyte[])std.file.read(filename);
    }

private:
    string filename;
    ubyte[] data;

    void bail(string msg = null) {
        throwIf(true, msg !is null ? msg : "Something went wrong");
    }
}
