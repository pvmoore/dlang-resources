module resources.algorithms.deflate;
/**
 *  https://tools.ietf.org/html/rfc1951
 *  https://en.wikipedia.org/wiki/DEFLATE
 *  https://www.infinitepartitions.com/art001.html
 *  https://www.zlib.net/feldspar.html
 */
public:

import resources.algorithms.deflate.DeflateCompressor;
import resources.algorithms.deflate.DeflateDecompressor;
import resources.algorithms.deflate.Distances;
import resources.algorithms.deflate.MetaHuffman;
import resources.algorithms.deflate.InputWindow;
import resources.algorithms.deflate.Lengths;
import resources.algorithms.deflate.OutputWindow;
import resources.algorithms.deflate.Symbol;

import resources.algorithms.entropy.Huffman;
