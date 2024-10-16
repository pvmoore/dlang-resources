module resources.algorithms.entropy.model.FastOrder0DynamicModel;

import resources.all;

/**
 * Faster implementation of Order0DynamicModel where updating and reading the 
 * cumulative weights is O(log n).
 */
final class FastOrder0DynamicModel : EntropyModel {
public:
    uint getNumSymbols() {
        return counts.getNumCounts();
    }

    this(uint numSymbols, ulong factor = 1) {
        this.factor = factor;
        this.counts = new CumulativeCounts(numSymbols, 1);
    }
    void addSymbols(uint count) {
        counts.expandBy(count, 1);
    }
    override MSymbol getSymbolFromIndex(uint index) {
        auto symbol = counts.getSymbolFromIndex(index);
        counts.add(index, factor);
        return symbol;
    }
    override MSymbol getSymbolFromRange(ulong range) {
        MSymbol symbol = counts.getSymbolFromRange(range);
        counts.add(symbol.value, factor);
        return symbol;
    }
    override ulong getScale() {
        return counts.getTotal();
    }

    // debugging methods below here

    MSymbol peekSymbolFromIndex(uint index) {
        return counts.getSymbolFromIndex(index);
    }
    MSymbol peekSymbolFromRange(ulong range) {
        return counts.getSymbolFromRange(range);
    }
    void dumpRanges() {
        writefln("Ranges {");

        ulong[] c = counts.peekCounts();

        foreach(i; 0..c.length.as!uint) {
            auto s = counts.getSymbolFromIndex(i);
            writefln(" '%s'\t%s..<%s (freq = %s) cumulativeWeights[%s] = %s", i, s.low, s.high, s.high-s.low, i, s.value);
        }
        writefln("} scale = %s", counts.getTotal());
    }
private:
    CumulativeCounts counts;
    ulong factor;
}
