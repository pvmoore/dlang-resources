module resources.algorithms.deflate.DeflateDecompressor;

import resources.algorithms.deflate;
import resources.all;

final class DeflateDecompressor {
private:

public:
    ubyte[] decompress(ByteReader byteReader) {
        chat("Deflate.decompress");

        auto byteWriter = new ArrayByteWriter;
        auto output     = new OutputWindow(byteWriter, 32768);
        auto bitReader  = byteReader.getBitReader();

        while(false==processBlock(bitReader, output)) {
          
        }
        chat("Finished. Bytes decoded = %s", byteWriter.length);

        return byteWriter.getArray;
    }
private:
    bool processBlock(BitReader r, OutputWindow output) {
        chat("processBlock");

        bool isLast = r.read(1)==1;
        chat("\tIs last block = %s", isLast);

        auto btype = r.read(2);
        chat("BTYPE = %s", btype);

        final switch(btype) {
            case 0: 
                // Stored block is byte aligned
                r.skipToEndOfByte();
                decompressStoredBlock(r, output);
                break;
            case 1:
                decompressFixedHuffmanBlock(r, output);
                break;
            case 2:
                decompressDynamicHuffmanBlock(r, output);
                break;
            case 3:
                throw new Error("Error in compressed data");
        }   
        return isLast;     
    }
    void decompressStoredBlock(BitReader r, OutputWindow output) {
        chat("\tStored block");
        uint length    = r.read(16);
        uint notLength = r.read(16);
        if(length != ~notLength) throw new Error("Error in compressed data");

        chat("\tCopying %s bytes of data", length);
        // copy the raw data
        for(auto i=0; i<length; i++) {
            output.write(cast(ubyte)r.read(8));
        }
    }
    void decompressFixedHuffmanBlock(BitReader r, OutputWindow output) {
        chat("\tFixed Huffman");
        todo("Implement Fixed Huffman block");
    }
    void decompressDynamicHuffmanBlock(BitReader r, OutputWindow output) {
        chat("\tDynamic Huffman");

        // Get the huffman trees
        auto numLiteralCodes = r.read(5) + 257; // (257..286)
        auto numDistCodes    = r.read(5) + 1;   // (  1..32)
        auto numBitLengthCodes = r.read(4) + 4; // (  4..19)
        chat("\tNum literal codes  = %s", numLiteralCodes);
        chat("\tNum distance codes = %s", numDistCodes);
        chat("\tNum bit length codes = %s", numBitLengthCodes);

        auto metaTree = MetaHuffman.readBitLengths(r, numBitLengthCodes);
    
        static if(false && chatty) {
            chat("Meta tree = {\n%s}", metaTree.toString);
        }

        auto litTree  = metaTree.decodeTree(r, numLiteralCodes);
        static if(false && chatty) {
            chat("Literal tree = {\n%s}", litTree.toString);
            chat("# leaves = %s", litTree.getNumLeafNodes);
        }
        auto distTree = metaTree.decodeTree(r, numDistCodes);
        static if(false && chatty) {
            chat("Distance tree = {\n%s}", distTree.toString);
            chat("# leaves = %s", distTree.getNumLeafNodes);
        }

        decompressBlock(r, litTree, distTree, output);
    }
    void decompressBlock(BitReader r, Huffman litTree, Huffman distTree, OutputWindow output) {
        chat("decompressBlock");

        while(true) {
            auto code = litTree.decode(r);
            //chat("\tcode=%s", code);

            switch(code) {
                case 0:..case 255:
                    output.write(code.as!ubyte);
                    break;
                case 256:
                    return;
                default:
                    auto len = Lengths.decode(code, r);
                    //chat("length = %s", len);
                    auto distCode = distTree.decode(r);
                    //chat("distCode = %s", distCode);
                    auto dist = Distances.decode(distCode, r);
                    //chat("dist = %s", dist);
                    output.copy(dist, len);
                    break;
            }
        }
    }
}