module resources.algorithms.entropy.Huffman;

import resources.all;

import std.algorithm.searching : maxElement;
import core.bitop : bitswap;

class Huffman {
protected:
    struct Node {
        Node* left;
        Node* right;
        int value;

        bool isLeaf() { return left is null && right is null; }
        void write(StringBuffer to, string indent) {
            if(value!=-1) to.add(indent~" (%s)\n", value);
            if(left)  left.write(to, indent~"0");
            if(right) right.write(to, indent~"1");
        }
    }
    Node* top;
    uint numLeaves;
public:
    uint getNumLeafNodes() { return numLeaves; }
    /**
     *  Construct a Huffman tree from bit lengths.
     *  (https://tools.ietf.org/html/rfc1951 Section 3.2.2)
     */
    this(uint[] bitLengths) {
 
        uint[] bitCodes = new uint[bitLengths.length];
     
        auto maxBits = bitLengths.maxElement();

        // bl_count <- the number of codes at each bit length
        uint[] bl_count = new uint[maxBits+1];
        foreach(bl; bitLengths) {
            bl_count[bl]++;
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

        // Create the Huffman tree using the bit code and length 
        top = new Node(null,null,-1);

        for(int i=0; i<bitLengths.length; i++) {
            if(bitLengths[i]==0) continue;

            uint bits  = bitCodes[i];
            uint bit   = 1;
            Node* node = top;
            for(int j=0; j<bitLengths[i];j++) {
                if((bits&bit)==0) {
                    // left
                    if(!node.left) node.left = new Node(null,null,-1);
                    node = node.left;
                } else {
                    // right
                    if(!node.right) node.right = new Node(null,null,-1);
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
    }
    /** 
     *  Read bits until a value is found. 
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
    override string toString() {
        auto buf = new StringBuffer;
        top.write(buf, "");
        return buf.toString;
    }
}