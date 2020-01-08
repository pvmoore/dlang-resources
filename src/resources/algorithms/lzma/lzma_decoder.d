module resources.algorithms.lzma.lzma_decoder;

import resources.all;

final class LZMADecoder {
private:
    LZMARangeDecoder rangeDecoder;

    BitTreeDecoder[4] posSlotDecoder;
    uint dictionarySize;
    ByteReader input;
public:
    this(ByteReader input,
         uint dictionarySize,
         uint numLitContextBits,
         uint litPosBits,
         uint numPosStates)
    {
        this.input = input;
        this.dictionarySize = dictionarySize;
        this.rangeDecoder = new LZMARangeDecoder(input);

        foreach(ref d; posSlotDecoder) {
            d = new BitTreeDecoder(rangeDecoder, input, 6);
        }
    }

}

//===================================================================================================

final class LiteralDecoder {
    static final class InnerLiteralDecoder {
        ushort[] decoders;
        this() {
            this.decoders = new ushort[0x300]; // 768
            foreach(ref d; decoders) {
			    d = (LZMARangeDecoder.kBitModelTotal >>> 1);
            }
        }
        byte decodeNormal(LZMARangeDecoder rangeDecoder) {
            int symbol = 1;
            do{
                symbol = (symbol << 1) | rangeDecoder.decodeBit(decoders, symbol);
            }while(symbol < 0x100);
            return cast(byte)symbol;
        }
        byte decodeWithMatchByte(LZMARangeDecoder rangeDecoder, byte matchByte) {
            int symbol = 1;
            do{
                int matchBit = (matchByte >> 7) & 1;
                matchByte <<= 1;
                int bit = rangeDecoder.decodeBit(decoders, ((1 + matchBit) << 8) + symbol);
                symbol = (symbol << 1) | bit;
                if(matchBit != bit) {
                    while (symbol < 0x100)
                        symbol = (symbol << 1) | rangeDecoder.decodeBit(decoders, symbol);
                    break;
                }
            }
            while(symbol < 0x100);
            return cast(byte)symbol;
        }
    }
    InnerLiteralDecoder[] coders;
    uint numPosBits;
    uint numPrevBits;
    uint posMask;

    this(uint numPosBits, uint numPrevBits) {
        this.numPosBits = numPosBits;
        this.numPrevBits = numPrevBits;
        this.posMask = (1<<numPosBits) - 1;

        auto numStates = 1 << (numPrevBits + numPosBits);
        this.coders = new InnerLiteralDecoder[numStates];
        foreach(ref c; coders) {
            c = new InnerLiteralDecoder();
        }
    }
    InnerLiteralDecoder getCoder(int pos, byte prevByte) {
        return coders[((pos & posMask) << numPrevBits) + ((prevByte & 0xFF) >>> (8 - numPrevBits))];
    }
}