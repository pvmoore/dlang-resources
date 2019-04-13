module resources.algorithms.entropy.EntropyModel;

import resources.all;
import std.algorithm.iteration : sum;

struct MSymbol {
	ulong low;
	ulong high;
    int value;
}

interface EntropyModel {
    MSymbol getSymbolFromValue(int value);
    MSymbol getSymbolFromRange(ulong range);
    ulong   getScale();
}

final class StaticOrder0Model : EntropyModel {
private:
    ulong[] cumulativeWeights;
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
    MSymbol getSymbolFromValue(int value) {
        return MSymbol(cumulativeWeights[value], cumulativeWeights[value+1], value);
    }
    MSymbol getSymbolFromRange(ulong range) {
        // naive implementation
        for(int i = 0 ;i < cumulativeWeights.length ;i++) {
            if(range < cumulativeWeights[i+1]) return MSymbol(cumulativeWeights[i], cumulativeWeights[i+1], i);
        }
        assert(false);
    }
    ulong getScale() {
        return cumulativeWeights[$-1];
    }
}

// class DynamicOrder0Model : EntropyModel {
// private:
//     uint[] counts;
//     uint scale;
// public:
//     this(int numSymbols) {
//         this.counts.length = numSymbols;
//         this.scale         = 0;
//     }
//     MSymbol getSymbolFromValue(int value) {
//         todo();

//         update(value);
//         return MSymbol();
//     }
//     MSymbol getSymbolFromRange(uint range) {
//         todo();
//         return MSymbol();
//     }
//     uint getScale() {
//         return scale;
//     }
// private:
//     void update(int value) {

//     }
// }