module resources.algorithms.entropy.model.Order0DynamicModel;

import resources.all;

final class Order0DynamicModel : EntropyModel {
public:
    this(uint numSymbols) {
        cumulativeWeights.length = numSymbols + 1;
        foreach(i; 0..numSymbols) {
            cumulativeWeights[i] = i;
        }
        cumulativeWeights[$-1] = numSymbols;
    }
    override MSymbol getSymbolFromValue(int value) {
        ulong low = cumulativeWeights[value];
        ulong high = cumulativeWeights[value+1];
        auto symbol = MSymbol(low, high, getScale(), value);
        updateFrequencies(value);
        return symbol;
    }
    override MSymbol getSymbolFromRange(ulong range) {
        // naive implementation
        MSymbol symbol;
        for(int i = 0; i < cumulativeWeights.length; i++) {
            if(range < cumulativeWeights[i+1]) { 
                symbol = MSymbol(cumulativeWeights[i], cumulativeWeights[i+1], getScale(), i);
                break;
            }
        }
        updateFrequencies(symbol.value);
        return symbol;
    }
    override ulong getScale() {
        return cumulativeWeights[$-1];
    }

    // debugging methods below here

    MSymbol peekSymbolFromValue(int value) {
        ulong low = cumulativeWeights[value];
        ulong high = cumulativeWeights[value+1];
        auto symbol = MSymbol(low, high, getScale(), value);
        return symbol;
    }
    MSymbol peekSymbolFromRange(ulong range) {
        // naive implementation
        MSymbol symbol;
        for(int i = 0; i < cumulativeWeights.length; i++) {
            if(range < cumulativeWeights[i+1]) { 
                symbol = MSymbol(cumulativeWeights[i], cumulativeWeights[i+1], getScale(), i);
                break;
            }
        }
        return symbol;
    }
    void dumpRanges() {
        writefln("Ranges {");

        foreach(i; 0..cumulativeWeights.length-1) {
            ulong w0 = cumulativeWeights[i];
            ulong w1 = cumulativeWeights[i+1];
            writefln(" '%s'\t%s..<%s (freq = %s) cumulativeWeights[%s] = %s", i, w0, w1, w1-w0, i, cumulativeWeights[i]);
        }
        writefln("} scale = %s", cumulativeWeights[$-1]);
    }
private:
    ulong[] cumulativeWeights;

    void updateFrequencies(int value) {
        foreach(i; value+1..cumulativeWeights.length) {
            cumulativeWeights[i]++;
        }
    }
}
