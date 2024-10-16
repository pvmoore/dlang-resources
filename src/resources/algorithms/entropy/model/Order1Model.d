module resources.algorithms.entropy.model.Order1Model;

import resources.all;

/**
 * Tracks a 2 symbol history for all symbols.
 */
final class Order1Model : EntropyModel {
public:
    this(uint numSymbols, ulong factor = 1) {
        this.factor = factor;
        initialise(numSymbols);
    }
    override MSymbol getSymbolFromIndex(uint index) {
        auto symbol = currentCounts.getSymbolFromIndex(index);
        update(index);
        return symbol;
    }
    override MSymbol getSymbolFromRange(ulong range) {
        auto symbol = currentCounts.getSymbolFromRange(range);
        update(symbol.value);
        return symbol;
    }
    override ulong getScale() {
        return currentCounts.getTotal();
    }
private:
    CumulativeCounts[] array; 
    CumulativeCounts currentCounts;
    ulong factor;
    int prevIndex;

    void initialise(uint numSymbols) {
        array.length = numSymbols;
        prevIndex = -1;
        currentCounts = new CumulativeCounts(numSymbols, 1);
        foreach(i; 0..numSymbols) {
            array[i] = new CumulativeCounts(numSymbols, 1);
        }
    } 
    void update(uint index) {
        if(prevIndex!=-1) {
            currentCounts = array[prevIndex];

            // Update order 1 probabilities
            currentCounts.add(index, factor);

            // Uncomment here to update order 0 probabilities
            // foreach(i; 0..array.length) {
            //     array[i].add(index, 20);
            // }
        }
        prevIndex = index;
    }
}
