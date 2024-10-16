module resources.algorithms.entropy.model.FastOrder0StaticModel;

import resources.all;

/**
 * Faster implementation of Order0StaticModel where updating and reading the 
 * cumulative weights is O(log n). For this model the getSymbolFromIndex() method
 * is actually slightly slower but the getSymbolFromRange() is faster.
 * Could be improved by using the naive ulong[] cumulativeWeights from Order0StaticModel
 * for getSymbolFromIndex().
 */
final class FastOrder0StaticModel : EntropyModel {
public:
    this(ulong[] symbolFrequencies) {
        this.counts = new CumulativeCounts(symbolFrequencies.length.as!uint, 0);
        foreach(i; 0..symbolFrequencies.length.as!uint) {
            counts.add(i, symbolFrequencies[i]);
        }
    }
    override MSymbol getSymbolFromIndex(uint index) {
        return counts.getSymbolFromIndex(index);
    }
    override MSymbol getSymbolFromRange(ulong range) {
        return counts.getSymbolFromRange(range);
    }
    override ulong getScale() {
        return counts.getTotal();
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
}
