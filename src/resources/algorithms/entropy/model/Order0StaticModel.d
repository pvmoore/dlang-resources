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
private:
    ulong[] cumulativeWeights;    
}
