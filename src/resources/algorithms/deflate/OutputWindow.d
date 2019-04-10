module resources.algorithms.deflate.OutputWindow;

import resources.algorithms.deflate;
import resources.all;

final class OutputWindow {
private:
    ubyte[] array;
    int len;
    int pos;
    ByteWriter byteWriter;
public:
    this(ByteWriter writer, int length) {
        this.len = length;
        this.array.length = length;
        this.byteWriter   = writer;
    }
    void write(ubyte b) {
        array[pos] = b;
        byteWriter.write!ubyte(b);
        //chat("..%s", cast(char)b);

        if(++pos==array.length) pos = 0;
    }
    void copy(int distance, int count) {
        
        for(int i=0; i<count; i++) {
           copy(distance);
        }
    }
private:
    void copy(uint distance) {
        int i = pos-distance;
        if(i<0) i += len;

        write(array[i]);
    }
}