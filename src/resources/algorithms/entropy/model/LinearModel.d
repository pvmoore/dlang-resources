module resources.algorithms.entropy.model.LinearModel;

import resources.all;

/**
 * An EntropyModel which encodes/decodes without any probability distribution
 * ie. there will be no compression. This is useful if you are encoding some data that
 * you know is random.
 */
final class LinearModel : EntropyModel {
public:
    this(uint numSymbols) {
        this.numSymbols = numSymbols;
    }
    MSymbol getSymbolFromIndex(uint index) {
        return MSymbol(index, index+1, numSymbols, index);
    }
    MSymbol getSymbolFromRange(ulong range) {
        return MSymbol(range, range+1, numSymbols, range.as!int);
    }
    ulong getScale() {
        return numSymbols;
    }
private:
    uint numSymbols;
}
