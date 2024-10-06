module resources.algorithms.entropy.model.Order0DynamicModel;

import resources.all;

final class Order0DynamicModel : EntropyModel {
public:
    this(uint numSymbols) {
        this.counts.length = numSymbols;
        this.scale         = 0;
    }
    MSymbol getSymbolFromValue(int value) {
        todo();

        update(value);
        return MSymbol();
    }
    MSymbol getSymbolFromRange(ulong range) {
        todo();
        return MSymbol();
    }
    ulong getScale() {
        return scale;
    }
private:
    ulong[] counts;
    ulong scale;

    void update(int value) {

    }
}
