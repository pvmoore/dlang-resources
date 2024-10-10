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
 *         0000000000000000] // row 3
 */
final class CumulativeCounts {
public:
    ulong getTotal() {
        return total; 
    }
    ulong[] peekCounts() {
        return tree[$-NUM_COUNTS..$];
    }

    this(uint numCounts, ulong initialCount = 0) {
        this.MAX_VALUE = numCounts - 1;
        if(popcnt(numCounts) == 1) {
            this.NUM_COUNTS = numCounts;
        } else {
            this.NUM_COUNTS = 1 << (bsr(numCounts) + 1);
        }
        this.NUM_COUNTS_DIV = bsf(this.NUM_COUNTS) - 1; 
        createTree(initialCount);
    }
    void add(uint value, uint count = 1) {
        assert(value <= MAX_VALUE);
        
        uint offset = 0;
        uint num    = 2;
        uint div    = NUM_COUNTS_DIV;

        while(num <= NUM_COUNTS) {
            uint v = value >>> div;

            tree[offset+v] += count;

            offset += num;
            num <<= 1;
            div--;
        }
        total += count;
    }
    ulong getCountByIndex(uint index) {
        ulong count     = 0;
        uint treeOffset = 0;
        uint size       = 2;
        uint window     = NUM_COUNTS;
        uint pivot      = NUM_COUNTS >>> 1;

        while(window > 1) {
            // writefln("--------------------");
            // writefln("pivot      = %s", pivot);
            // writefln("treeOffset = %s", treeOffset);
            // writefln("size       = %s", size);
            // writefln("window     = %s", window);

            if(index >= pivot) {
                // go right
                auto leftPos   = treeOffset + (pivot/window)*2;
                auto leftValue = tree[leftPos];
                count += leftValue;
                pivot += window>>>2;
                //writefln("leftPos    = %s", leftPos);
                //writefln("go right (adding %s from tree[%s])", leftValue, leftPos);
                
            } else {
                // go left
                pivot -= window>>>2;
            }
            treeOffset += size;
            size <<= 1;
            window >>>= 1;
        }

        // add the final count
        count += tree[tree.length-NUM_COUNTS+index];

        return count;
    }
    ulong getCountByRange(uint range) { 
        uint treeOffset = 0;
        uint index  = 0;
        ulong sum   = 0;
        uint size   = 2;
        uint window = NUM_COUNTS >>> 1;
        uint shift  = NUM_COUNTS_DIV;

        while(size <= NUM_COUNTS) {
            uint n = index >>> shift;
            ulong value = tree[treeOffset+n];
            //writefln("size: %s, window: %s, index: %s, shift: %s, treeOffset: %s, n: %s", 
            //    size, window, index, shift, treeOffset, n);
            //writefln(" value = %s, sum = %s, (sum+value = %s)", value, sum, sum+value);

            if(range >= sum + value) {
                // go right
                index += window;
                sum += value;
            } else {
                // go left
            }

            window >>>= 1;
            shift--;
            treeOffset += size;
            size <<= 1;
        }
        return index;
    }
    void dumpTree() {
        uint num = 2;
        uint prev = 0;
        while(num <= NUM_COUNTS) {
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
    const uint MAX_VALUE;      // the 
    const uint NUM_COUNTS;     // power of 2 number of counts
    const uint NUM_COUNTS_DIV; // bsf(numCounts) - 1
    ulong[] tree;
    ulong total;

    void createTree(ulong initialCount) {
        uint length = 0;
        uint num = 2;
        do{ 
            length += num;
            num <<= 1;
        }while(num <= NUM_COUNTS);
        tree.length = length;

        // Set the initial counts if initialCount is not 0
        if(initialCount > 0) {
            ulong count = initialCount;
            uint size = NUM_COUNTS;
            auto index = tree.length-NUM_COUNTS;
            while(size > 1) {
                tree[index..index+size] = count;
                count <<= 1;
                size >>>= 1;
                index -= size; 
            }
            total += initialCount * NUM_COUNTS;
        }
    }
}
