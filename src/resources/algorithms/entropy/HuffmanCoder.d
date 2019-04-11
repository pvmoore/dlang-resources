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
        uint depth;
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
        Node setDepth(uint d) { 
            this.depth = d; 
            if(left) left.setDepth(d+1);
            if(right) right.setDepth(d+1);
            return this; 
        }

        bool isLeaf() { return left is null && right is null; }
        void write(StringBuffer to, string indent) {
            if(value!=-1) to.add(indent~" [value=%s, depth=%s]\n", value, depth);
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
    uint numLeaves, smallestBitLength, largestBitLength;
public:
    uint getNumLeafNodes()      { return numLeaves; }
    uint getSmallestBitLength() { return smallestBitLength; }
    uint getLargestBitLength()  { return largestBitLength; }

    /**
     *  Construct a Huffman tree from bit lengths.
     *  (https://tools.ietf.org/html/rfc1951 Section 3.2.2)
     */
    HuffmanCoder createFromBitLengths(uint[] bitLengths) { 
        
        uint[] bitCodes = new uint[bitLengths.length];
     
        auto maxBits = bitLengths.maxElement();

        this.largestBitLength  = 0;
        this.smallestBitLength = uint.max; 

        // bl_count <- the number of codes at each bit length
        uint[] bl_count = new uint[maxBits+1];
        foreach(bl; bitLengths) {
            bl_count[bl]++;

            if(bl > largestBitLength) largestBitLength = bl;
            if(bl < smallestBitLength) smallestBitLength = bl;
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
        numLeaves = 0;

        for(int i=0; i<bitLengths.length; i++) {
            if(bitLengths[i]==0) continue;

            uint bits = bitCodes[i];
            uint bit  = 1;
            Node node = top;
            for(int j=0; j<bitLengths[i];j++) {
                if((bits&bit)==0) {
                    // left
                    if(!node.left) node.left = new Node().setDepth(node.depth+1);
                    node = node.left;
                } else {
                    // right
                    if(!node.right) node.right = new Node().setDepth(node.depth+1);
                    node = node.right;
                }  
                bit<<=1;     
            }
            node.value = i;
            numLeaves++;
        }
        static if(false && chatty) {
            chat("tree=\n%s", this.toString);
        }
        return this;
    }
    HuffmanCoder createFromFrequencies(uint[] frequencies) {

        auto q = makeLowPriorityQueue!Node;

        // Populate queue
        foreach(i, freq; frequencies) {
            if(freq>0) {
                q.push( new Node(freq, i.as!int) );
            }
        }
        this.numLeaves = q.length.as!uint;

        // Order the nodes
        while(q.length > 1) {
            // Get 2 nodes with lowest freq
            auto left  = q.pop();
            auto right = q.pop();
            left.setDepth(1);
            right.setDepth(1);
            // Create a new branch node
            q.push( new Node(left, right, left.freq + right.freq, -1) );
        }
        // The final remaining item in the queue is the top of the tree 
        this.top = q.pop();

        // Calculate stats
        this.largestBitLength  = 0;
        this.smallestBitLength = uint.max; 

        recurseLeaves((Node leaf) {
            if(leaf.depth > largestBitLength) largestBitLength = leaf.depth;
            if(leaf.depth < smallestBitLength) smallestBitLength = leaf.depth;
        });

        return this;
    }
    /** 
     *  Read bits until a leaf is found. 
     */
    uint decode(BitReader r) {
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
     *  Execute functor on all leaf nodes in the tree in no particular order.
     */
    void recurseLeaves(void delegate(Node n) functor) {
        if(top) _recurse(top, functor);
    }
    override string toString() {
        auto buf = new StringBuffer;
        top.write(buf, "");
        return buf.toString;
    }
private:
    void _recurse(Node n, void delegate(Node n) functor) {
        if(n.isLeaf) functor(n);
        else {
            if(n.left) _recurse(n.left, functor);
            if(n.right) _recurse(n.right, functor);
        }
    }
}