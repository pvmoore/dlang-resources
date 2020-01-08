module resources.algorithms.lzma.bittree_decoder;

import resources.all;

final class BitTreeDecoder {
private:
    LZMARangeDecoder rangeDecoder;
    ByteReader input;
    int numBitLevels;
    ushort[] models;
public:
    this(LZMARangeDecoder rangeDecoder, ByteReader input, int numBitLevels) {
        this.rangeDecoder = rangeDecoder;
        this.input = input;
        this.numBitLevels = numBitLevels;
        this.models = new ushort[1 << numBitLevels];

        // Init model
        const kBitModelTotal = 1 << 11;
        for(int i = 0; i < models.length; i++)
			models[i] = (kBitModelTotal >>> 1);
    }
    int decode() {
		int m = 1;
		for(int bitIndex = numBitLevels; bitIndex != 0; bitIndex--) {
			m = (m << 1) + rangeDecoder.decodeBit(models, m);
        }
		return m - (1 << numBitLevels);
	}
}