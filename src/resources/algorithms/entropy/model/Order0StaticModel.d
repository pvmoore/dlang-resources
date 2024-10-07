module resources.algorithms.entropy.model.Order0StaticModel;

import resources.all;

final class Order0StaticModel : EntropyModel {
public:
    this(ulong[] symbolFrequencies) {
        this.cumulativeWeights.length = symbolFrequencies.length + 1;
        ulong weight = 0;
        foreach(i, freq; symbolFrequencies) {
            cumulativeWeights[i] = weight;
            weight              += freq;
        }
        cumulativeWeights[$-1] = weight;
    }
    override MSymbol getSymbolFromValue(int value) {
        return MSymbol(cumulativeWeights[value], cumulativeWeights[value+1], getScale(), value);
    }
    override MSymbol getSymbolFromRange(ulong range) {
        // naive implementation
        for(int i = 0; i < cumulativeWeights.length; i++) {
            if(range < cumulativeWeights[i+1]) {
                return MSymbol(cumulativeWeights[i], cumulativeWeights[i+1], getScale(), i);
            }
        }
        assert(false);
    }
    override ulong getScale() {
        return cumulativeWeights[$-1];
    }
    void dumpRanges() {
        writefln("Ranges {");

        foreach(i; 0..cumulativeWeights.length) {
            ulong w0 = i > 0 ? cumulativeWeights[i-1] : 0;
            ulong w1 = cumulativeWeights[i];
            writefln(" '%s'\t%s..<%s (freq = %s) cumulativeWeights[%s] = %s", i, w0, w1, w1-w0, i, cumulativeWeights[i]);
        }
        writefln("} scale = %s", cumulativeWeights[$-1]);
    }
private:
    ulong[] cumulativeWeights;    
}
