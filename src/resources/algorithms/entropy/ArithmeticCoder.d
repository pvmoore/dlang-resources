module resources.algorithms.entropy.ArithmeticCoder;

 import resources.all;

/**
 *  https://en.wikipedia.org/wiki/Arithmetic_coding
 *  https://marknelson.us/posts/2014/10/19/data-compression-with-arithmetic-coding.html
 *
 */
final class ArithmeticCoder {
private:
    const ulong FULL     = 0x00000000_8000_0000L;
    const ulong HALF     = 0x00000000_4000_0000L;
    const ulong MASK     = 0x00000000_ffff_ffffL;
    const uint CODE_BITS = 32;

    enum State { NONE, ENCODING, DECODING }

    EntropyModel model;
    State state = State.NONE;
    ulong low;
    ulong high;
    ulong code;
    int numUnderflowBits;
public:
    this(EntropyModel model) {
        this.model = model;
    }
    void beginEncoding() {
        assert(state == State.NONE);
        this.state = State.ENCODING;
        this.high  = MASK;
        this.low   = 0;
        this.code  = 0;
        this.numUnderflowBits = 0;
    }
    void encode(BitWriter w, uint value, EntropyModel overrideModel = null) {
        assert(state == state.ENCODING);

        auto theModel = overrideModel ? overrideModel : model;
        auto symbol  = theModel.getSymbolFromIndex(value);

        ulong range = ( high-low ) + 1L;
		high  	    = (low + (( range * symbol.high ) / symbol.scale - 1L) & MASK);
		low   	    = (low + (( range * symbol.low )  / symbol.scale     ) & MASK);
   
        while(true) {
            if(( high & FULL ) == ( low & FULL )) {
                uint bit = (high & FULL) !=0; 

                w.write(bit, 1);

                bit = ~bit;
                while(numUnderflowBits > 0) {
					w.write(bit, 1);
                    numUnderflowBits--;
				}
            } else if(( (low & HALF)!=0L ) && ( (high & HALF)==0L )) {
                numUnderflowBits++;
                low  &= (HALF-1L);
				high |= HALF;
            } else return;

            low  <<= 1; 
            high <<= 1;
            high  |= 1;

            low  &= MASK;
            high &= MASK;
        } 
    }
    void endEncoding(BitWriter w) {
        assert(state == State.ENCODING);
        uint bit = (low & HALF) !=0; 
        w.write(bit, 1);

        numUnderflowBits++;
        bit = ~bit;
        while(numUnderflowBits > 0) {
            w.write(bit, 1);
            numUnderflowBits--;
        }
        w.flush();
        state = State.NONE;
    }
    void beginDecoding(BitReader r) {
        assert(state == State.NONE);
        this.state = State.DECODING;
        this.high  = MASK;
        this.low   = 0;
        this.code  = 0;
        this.numUnderflowBits = 0;

        for(uint i = 0; i < CODE_BITS; i++) {
			code <<= 1;
			code  += r.read(1);
		}
    }
    int decode(BitReader r, EntropyModel overrideModel = null) {
        assert(state == State.DECODING);

        auto theModel  = overrideModel ? overrideModel : model;
        ulong range    = ( high - low ) + 1L;
		ulong count    = (((( ( code - low ) +1L) * theModel.getScale() - 1L) / range) & MASK);
        MSymbol symbol = theModel.getSymbolFromRange(count);

        // Note that the scale used here must be the one from the symbol because in the case of the
        // dynamic model the previous scale will change after we get a symbol.
		high      	= (low + (( range * symbol.high ) / symbol.scale -1L) & MASK);
		low       	= (low + (( range * symbol.low )  / symbol.scale    ) & MASK);

        while(true) {
            if((high & FULL) == (low & FULL)) {
				
			} else if((low & HALF) == HALF && (high & HALF) == 0L ) {
                code  ^= HALF;
				low   &= (HALF-1L);
				high  |= HALF;
            } else {
                return symbol.value;
            }

            low  <<= 1;
			high <<= 1;
			high |= 1L;
			code <<= 1;
	    
			low  &= MASK;
			high &= MASK;
			code &= MASK;
	    
			code += r.read(1);
        }
    }
    void endDecoding() {
        assert(state == State.DECODING);
        state = State.NONE;
    }
}
