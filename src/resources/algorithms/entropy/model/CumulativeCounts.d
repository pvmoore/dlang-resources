module resources.algorithms.entropy.model.CumulativeCounts;

import resources.all;
import core.bitop : bsf, bsr, popcnt;

/**
 * An array of cumulative weights where W[N] includes the sum of all weights to the left of it.
 * eg.
 * counts  = [0,1,0,2,1]
 * weights = [0,1,1,4,5]
 *
 * This implementation is O(log N)
 *
 * 16 counts example:
 *               pivot=8
 * ┌───────────────┬───────────────┐               
 * |       2       |       3       | 
 * ├───────┬───────┼───────┬───────┤  pivots at 4 and 12             
 * |   0   |   2   |   2   |   1   |
 * ├───┬───┼───┬───┼───┬───┼───┬───┤  pivots at 2,6,10 and 14             
 * | 0 | 0 | 0 | 2 | 1 | 1 | 0 | 1 |
 * ├─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┼─┬─┤  pivots at 1,3,5,7,9,11,13 and 15              
 * |0|0|0|0|0|0|1|1|1|0|0|1|0|0|0|1|
 * └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘  
 *  0 1 2 3 4 5 6 7 8 9 1 1 1 1 1 1
 *                      0 1 2 3 4 5   
 *
 * tree representation in memory:
 *
 * tree = [00                // row 0
 *         0000              // row 1
 *         00000000          // row 2
 *         0000000000000000] // row 3 (length = capacity)
 */
final class CumulativeCounts {
public:
    ulong getTotal() {
        return total; 
    }
    uint getCapacity() {
        return capacity;
    }
    uint getNumCounts() {
        return numCounts;
    }
    ulong[] peekCounts() {
        return tree[bottomRowOffset..bottomRowOffset+numCounts];
    }
    ulong[] peekWeightsLow() {
        return iota(0, numCounts).map!(it=>getSymbolFromIndex(it).low).array();
    }
    ulong[] peekWeightsHigh() {
        return iota(0, numCounts).map!(it=>getSymbolFromIndex(it).high).array();
    }

    this(uint numCounts, ulong initialCount) {
        recreateTree(numCounts, initialCount);
    }
    /** Add 'num' more counts */
    void expandBy(uint num, ulong initialCount) {
        //writefln("numCounts = %s, capacity = %s", numCounts, capacity);
        if(num == 0) return;
        if(numCounts+num <= capacity) {
            uint oldNumCounts = numCounts;
            numCounts += num;
            if(initialCount > 0) {
                tree[bottomRowOffset+oldNumCounts..bottomRowOffset+numCounts] = initialCount;
                total += initialCount*num;
                propagateTree();
            }
        } else {
            recreateTree(numCounts + num, initialCount);
        }
    }
    void add(uint value, ulong count = 1) {
        assert(value < numCounts);
        
        uint offset = 0;
        uint num    = 2;
        uint div    = capacityDiv;

        while(num <= capacity) {
            uint v = value >>> div;

            tree[offset+v] += count;

            offset += num;
            num <<= 1;
            div--;
        }
        total += count;
    }
    MSymbol getSymbolFromIndex(uint index) {
        ulong low       = 0;
        uint treeOffset = 0;
        uint size       = 2;
        uint shift      = capacityDiv;  
        uint pivot      = capacity >>> 1;
        uint window     = capacity >>> 2;

        while(size <= capacity) {

            bool goRight = index >= pivot;

            if(goRight) {
                auto n     = (pivot >>> shift) & 0xffff_fffe;
                auto value = tree[treeOffset + n];
                low   += value;
                pivot += window;
            } else {
                pivot -= window;
            }
            treeOffset += size;
            size <<= 1;
            window >>>= 1;
            shift--;
        }

        ulong high = low + tree[bottomRowOffset+index];

        return MSymbol(low, high, total, index);
    }
    MSymbol getSymbolFromRange(ulong range) { 
        uint treeOffset = 0;
        uint index      = 0;
        ulong low       = 0;
        uint size       = 2;
        uint window     = capacity >>> 1;
        uint shift      = capacityDiv;

        while(size <= capacity) {
            uint n       = index >>> shift;
            ulong value  = tree[treeOffset + n];
            bool goRight = range >= low + value; 

            if(goRight) {
                index += window;
                low   += value;
            } 

            treeOffset += size;
            size <<= 1;
            window >>>= 1;
            shift--;
        }

        ulong high = low + tree[bottomRowOffset+index];

        return MSymbol(low, high, total, index);
    }
    void dumpTree() {
        uint num = 2;
        uint prev = 0;
        while(num <= capacity) {
            writef("[%2s] ", prev);
            foreach(i; prev..prev+num) {
                writef("%s ", tree[i]);
            }
            writefln("");
            prev += num;
            num <<= 1;
        }
    }
private:
    // These should change rarely - only when the tree is created or is expanded
    uint numCounts;         // Number of active counts in the array
    uint capacity;          // Power of 2 number of counts (max counts we can hold before expanding the tree)
    uint capacityDiv;       // bsf(numCounts) - 1
    uint bottomRowOffset;   // Index of the start of the bottom row in the tree (tree.length - numCounts)

    ulong[] tree;
    ulong total;

    void recreateTree(uint newNumCounts, ulong initialCount) {
        uint oldNumCounts = this.numCounts;
        ulong[] oldCounts = oldNumCounts > 0 ? tree[bottomRowOffset..bottomRowOffset+oldNumCounts] : null;

        this.numCounts = newNumCounts;
        if(popcnt(numCounts) == 1) {
            this.capacity = numCounts;
        } else {
            this.capacity = 1 << (bsr(numCounts) + 1);
        }
        this.capacityDiv = bsf(this.capacity) - 1; 

        uint length = 0;
        uint num = 2;
        do{ 
            length += num;
            num <<= 1;
        }while(num <= capacity);

        // Create a new tree on the heap
        this.tree = new ulong[length];
        this.bottomRowOffset = tree.length.as!uint - capacity;

        // Copy the old counts if there are any
        if(oldNumCounts > 0) {
            tree[bottomRowOffset..bottomRowOffset+oldNumCounts] = oldCounts;
            assert(numCounts > oldNumCounts);

            // Initialise the new counts
            tree[bottomRowOffset+oldNumCounts..bottomRowOffset+numCounts] = initialCount;
            total += initialCount * (numCounts-oldNumCounts);

            propagateTree();

        // Set the initial counts if initialCount is not 0
        } else if(initialCount > 0) {
            // Initialise the new counts
            tree[bottomRowOffset..bottomRowOffset+numCounts] = initialCount;
            total += initialCount * numCounts;
            
            propagateTree();
        }
    }
    /** Iterate up the tree from the bottom, populating the counts of the upper tree nodes */
    void propagateTree() {
        uint size = capacity >>> 1;
        auto srcIndex  = tree.length-capacity;
        auto destIndex = srcIndex-size;

        while(size > 1) {
            foreach(i; 0..size) {
                tree[destIndex+i] = tree[srcIndex+i*2] + tree[srcIndex+1+i*2];
            }
            size >>>= 1;
            srcIndex = destIndex;
            destIndex -= size; 
        }
    }
}
