module resources.image.webp.WebP;

import resources.all;
import resources.image.webp.WebPReader;

/**
 * WebP - Web Picture format
 *
 * https://en.wikipedia.org/wiki/WebP
 * https://www.rfc-editor.org/rfc/rfc9649.html
 */
final class WebP : Image {
public:
    static WebP read(string filename) {
        return new WebPReader().read(filename);
    }
}
