module resources.image.jpeg.JPEG;

import resources.all;
import resources.image.jpeg.JFIFReader;

final class JPEG : Image {
public:
    static JPEG read(string filename) {
        return new JFIFReader().read(filename);
    }
}
