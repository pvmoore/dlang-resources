module resources.algorithms.lzma.range_decoder;

import resources.all;

final class LZMARangeDecoder {
private:
    ByteReader input;
    int range;
	int code;
public:
    enum kTopMask              = ~((1 << 24) - 1);
    enum kNumBitModelTotalBits = 11;
    enum kBitModelTotal        = (1 << kNumBitModelTotalBits);
    enum kNumMoveBits          = 5;

    this(ByteReader input) {
        this.input = input;
    }
    void beginDecoding() {
        this.code  = 0;
		this.range = -1;
		foreach(i; 0..5) {
			code = (code << 8) | input.read!ubyte;
        }
    }
    int decodeBit(ushort[] probs, int index) {
        int prob = probs[index];
		int newBound = (range >>> kNumBitModelTotalBits) * prob;
		if((code ^ 0x80000000) < (newBound ^ 0x80000000)) {
			range = newBound;
			probs[index] = cast(short)(prob + ((kBitModelTotal - prob) >>> kNumMoveBits));
			if((range & kTopMask) == 0) {
				code = (code << 8) | input.read!ubyte;
				range <<= 8;
			}
			return 0;
		} else {
			range -= newBound;
			code -= newBound;
			probs[index] = cast(short)(prob - ((prob) >>> kNumMoveBits));

			if((range & kTopMask) == 0) {
				code = (code << 8) | input.read!ubyte;
				range <<= 8;
			}
			return 1;
		}
    }
}