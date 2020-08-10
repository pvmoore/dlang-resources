module resources.algorithms.entropy.HuffmanCoder;

import resources.all;

import std.algorithm.searching : maxElement;
import core.bitop : bitswap;

class HuffmanCoder {
protected:
    final static class Node {
        Node left;
        Node right;
        uint freq;
        uint depth; // num bits
        uint bits;
        int value;

        this(uint freq = 0, int value = -1) {
            this.freq  = freq;
            this.value = value;
        }
        this(Node left, Node right, uint freq, int value) {
            this(freq, value);
            this.left  = left;
            this.right = right;
        }

        bool isLeaf() { return left is null && right is null; }
        void write(StringBuffer to, string indent) {
            if(value!=-1) to.add(indent~" [value=%%s, depth=%%s, bits=%%0%sb]\n".format(depth), value, depth, bits);
            if(left)  left.write(to, indent~"0");
            if(right) right.write(to, indent~"1");
        }

        // Comparison and equality based on frequency
        override int opCmp(Object other) const {
            uint o = other.as!Node.freq;
            return freq == o ? 0 : freq < o ? -1 : 1;
        }
        override bool opEquals(Object other) const {
            return freq == other.as!Node.freq;
        }
    }
    Node top;
    Node[int] valueToLeaf;
    uint shortestBitLength, longestBitLength;
public:
    uint getNumLeafNodes()      { return valueToLeaf.length.as!uint; }
    uint getShortestBitLength() { return shortestBitLength; }
    uint getLongestBitLength()  { return longestBitLength; }

    /**
     *  Construct a Huffman tree from bit lengths.
     *  (https://tools.ietf.org/html/rfc1951 Section 3.2.2)
     */
    HuffmanCoder createFromBitLengths(uint[] bitLengths) {

        uint[] bitCodes = new uint[bitLengths.length];

        auto maxBits = bitLengths.maxElement();

        this.longestBitLength  = 0;
        this.shortestBitLength = uint.max;

        // bl_count <- the number of codes at each bit length
        uint[] bl_count = new uint[maxBits+1];
        foreach(bl; bitLengths) {
            bl_count[bl]++;

            if(bl > longestBitLength) longestBitLength = bl;
            if(bl < shortestBitLength) shortestBitLength = bl;
        }

        uint[] nextCode = new uint[maxBits+1];
        uint code = 0;
        for(int bits=1; bits<=maxBits; bits++) {
            code = (code + bl_count[bits-1]) << 1;
            nextCode[bits] = code;
        }
        //chat("nextCode = %s", nextCode);

        for(long n = 0;  n < bitLengths.length; n++) {
            auto len = bitLengths[n];
            if(len != 0) {
                bitCodes[n] = bitswap(nextCode[len]) >> (32-len);
                nextCode[len]++;
            }
        }

        static if(false && chatty) {
            chat("bitCodes = %s", bitCodes);
            foreach(i, c; bitCodes) {
                if(bitLengths[i]==0) continue;
                string bits = "%032b".format(c);
                if(bits.length > bitLengths[i]) {
                    bits = bits[32-bitLengths[i]..$];
                }
                writefln("[%02s] bitlen=%s -> % 8s %04x", i, bitLengths[i], bits, c);
            }
            writefln("====\n");
        }

        // Create a new Huffman tree using the bit code and length
        top       = new Node();
        valueToLeaf.clear();

        for(int i=0; i<bitLengths.length; i++) {
            if(bitLengths[i]==0) continue;

            uint bits = bitCodes[i];
            uint bit  = 1;
            Node node = top;
            for(int j=0; j<bitLengths[i]; j++) {
                if((bits&bit)==0) {
                    // left
                    if(!node.left) {
                        node.left = new Node();
                        node.left.depth = j+1;
                    }
                    node = node.left;
                } else {
                    // right
                    if(!node.right) {
                        node.right = new Node();
                        node.right.depth = j+1;
                    }
                    node = node.right;
                }
                bit<<=1;
            }

            // Leaf
            node.value     = i;
            node.bits      = bits;
            valueToLeaf[i] = node;
        }

        return this;
    }
    HuffmanCoder createFromFrequencies(uint[] frequencies) {

        this.top               = null;
        this.longestBitLength  = 0;
        this.shortestBitLength = uint.max;
        this.valueToLeaf.clear();

        // Handle empty tree
        if(frequencies.length==0) {
            this.shortestBitLength = 0;
            return this;
        }

        auto q = makeLowPriorityQueue!Node;

        // Populate priority queue based on frequency
        foreach(i, freq; frequencies) {
            if(freq>0) {
                q.push( new Node(freq, i.as!int) );
            }
        }

        // Create the tree
        while(q.length > 1) {
            // Get 2 nodes with lowest freq
            auto left  = q.pop();
            auto right = q.pop();

            // Apply DEFLATE rules to create a canonical tree:
            // 1. Nodes with shorter codes are to the left of nodes with longer codes
            // 2. Nodes with codes of the same length, lower values are to the left

            bool swap = right.depth < left.depth;
            if(!swap && left.value!=-1 && right.value!=-1) {
                swap = right.value < left.value;
            }
            if(swap) {
                auto temp = left;
                left  = right;
                right = temp;
            }

            // Create a new branch node
            auto parent  = new Node(left, right, left.freq + right.freq, -1);

            // Depth is actually inverted here. We'll re-set it later
            parent.depth = max(left.depth, right.depth) + 1;

            q.push(parent);
        }
        // The single remaining item in the queue is the top of the tree
        this.top = q.pop();

        // Calculate stats, set bits, depth and valueToLeaf mapping
        _recurse(top, 0, 0, (Node leaf, uint bits, uint depth) {
            valueToLeaf[leaf.value] = leaf;
            leaf.bits  = bits;
            leaf.depth = depth;
            if(leaf.depth > longestBitLength) longestBitLength = leaf.depth;
            if(leaf.depth < shortestBitLength) shortestBitLength = leaf.depth;
        });

        return this;
    }
    /**
     *  Modify a tree which has bit lengths > maxBitLength
     */
    HuffmanCoder enforceMaxBitLength(uint maxBitLength) {
        if(longestBitLength <= maxBitLength) return this;

        // while longestBitLength > maxBitLength
        // leaf = a leaf where depth > maxBitLength
        // move it up the tree -- ensure DEFLATE rules are not broken

        todo();

        return this;
    }
    /**
     *  Read bits until a leaf is found.
     */
    int decode(BitReader r) {
        auto node = top;
        assert(node);
        while(true) {
            if(r.read(1)==0) {
                node = node.left;
            } else {
                node = node.right;
            }
            assert(node);
            if(node.isLeaf) return node.value;
        }
    }
    /**
     *  Write bits for leaf with value to BitWriter.
     */
    void encode(BitWriter w, int value) {
        auto node = valueToLeaf[value];
        w.write(node.bits, node.depth);
    }
    override string toString() {
        auto buf = new StringBuffer;
        top.write(buf, "");
        return buf.toString;
    }
private:
    /**
     *  Execute functor on leaf nodes in the tree in no particular order, starting from _n_.
     */
    void _recurse(Node n, uint bits, uint depth, void delegate(Node n, uint bits, uint depth) functor) {
        if(n.isLeaf) functor(n, bits, depth);
        else {
            if(n.left) _recurse(n.left,   bits,              depth+1, functor);
            if(n.right) _recurse(n.right, bits | (1<<depth), depth+1, functor);
        }
    }
}