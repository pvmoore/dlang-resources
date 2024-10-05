module resources.data.experimental.pdc2;

import resources.all;

enum Score { LENGTH, LENGTH_AND_COUNT }
enum SCORE = Score.LENGTH;

final class PDC2 {
private:
    static struct LengthCount {
        uint length;
        uint count;

        uint score() {
            static if(SCORE==Score.LENGTH) {
                return length;
            } else {
                return length*count;
            }
        }
        bool isBetterThan(LengthCount b) {
            static if(SCORE==Score.LENGTH) {
                if(length==b.length) return count > b.count;
                return score() > b.score();
            } else {
                return score() > b.score();
            }
        }
    }
    static struct Match {
        uint hash;
        uint offset;
        uint length;
        uint count;
        uint[] offsets;

        uint score() {
            static if(SCORE==Score.LENGTH) {
                return length;
            } else {
                return length*count;
            }
        }
        bool isBetterThan(Match b) {
            return score() > b.score();
        }
        string toString() { return "Match(%08x %s tokens * %s @ %s, score=%s)".format(hash, length, count, offset, score()); }
    }
    static struct Offsets {
        uint[] list;
    }

    ByteReader input;
    ushort[] tokens;
    uint numUniqueTokens;
    Offsets[uint] hashes;
public:
    this(string filename) {
        this.input = new FileByteReader(filename);
    }
    ubyte[] encode() {
        readAllTokens();

        foreach(i; 0..2000) {
            if(tokens.length<4) break;
            chat("Iteration %s ------------- length = %s (%s)", i, tokens.length, numUniqueTokens);
            auto match = findBestDuplicateRegion();

            rewriteTokens(match);
        }

        return null;
    }
private:
    void rewriteTokens(Match match) {
        chat("Rewriting tokens %s", match);

        ushort[] temp  = new ushort[tokens.length];
        uint[] offsets = match.offsets.sort().array;
        chat("offsets[%08x] = %s", match.hash, offsets);
        assert(offsets.length>1);

        uint src  = 0;
        uint dest = 0;

        void _copy(uint size) {
            temp[dest..dest+size] = tokens[src..src+size];
            src  += size;
            dest += size;
        }

        for(auto i=0; i<offsets.length; i++) {

            // copy literals up to start of region
            _copy(offsets[i]-src);

            // Add id token
            temp[dest++] = numUniqueTokens.to!ushort;

            if(i>0) {
                // Skip dup region if this is not the first one
                src += match.length;
            } else {
                // Copy the first region
                _copy(match.length);
            }
        }

        // Handle literals at the end
        _copy(tokens.length.to!uint-src);

        tokens = temp[0..dest];

        numUniqueTokens++;
    }
    Match findBestDuplicateRegion() {
        chat("Finding best duplicate region...");

        calculateHashes();

        Match bestMatch;

        foreach(k,v; hashes) {
            //chat("%08x = %s", k, v);

            if(v.list.length>1) {
                Match match = compareHashRegions(k, v.list);
                //chat("  match = %s", match);

                if(match.isBetterThan(bestMatch)) {
                    bestMatch = match;
                }
            }
        }
        //chat("  Best region = %s", bestMatch);
        return bestMatch;
    }
    void calculateHashes() {
        hashes.clear();
        expect(hashes.length==0);
        expect(tokens.length>3);

        import core.bitop : bsr;
        uint bitsRequired = bsr(numUniqueTokens-1)+1;
        //chat("  bitsRequired = %s", bitsRequired);

        foreach(i; 0..tokens.length-3) {
            uint hash =
                (tokens[i] << (bitsRequired*2)) |
                (tokens[i+1] << bitsRequired) |
                 tokens[i+2];

            auto p = hash in hashes;
            if(p) {
                p.list ~= cast(uint)i;
            } else {
                Offsets o;
                o.list ~= cast(uint)i;
                hashes[hash] = o;
            }
        }
        chat("  Hashes length = %s", hashes.length);
    }
    Match compareHashRegions(uint hash, uint[] offsets) {
        expect(offsets.length>1);

        //chat("  Comparing regions for hash %08x --> %s", hash, offsets);

        // The first 3 tokens should all be the same

        uint size       = offsets.length.as!uint;
        uint bestIndex  = 0;
        LengthCount bestLengthCount;
        uint[] bestIndices;

        uint[][uint] lengths; // key = length, value = list of indices

        for(uint index1 = 0; index1<size-1; index1++) {
            //chat("    -----------------------------------");
            lengths.clear();

            for(uint index2 = index1+1; index2<size; index2++) {
                //chat("    Index %s vs %s", index1, index2);

                auto len = compareTokenStreams(offsets[index1], offsets[index2]);

                auto p = len in lengths;
                if(p) {
                    lengths[len] ~= offsets[index2];
                } else {
                    lengths[len] = [offsets[index1], offsets[index2]];
                }
            }

            foreach(len,indices; lengths) {

                auto lc = LengthCount(len, indices.length.to!uint);
                if(lc.score() > bestLengthCount.score()) {
                    bestLengthCount = lc;
                    bestIndex       = index1;
                    bestIndices     = indices;
                }
            }
        }

        Match match = Match(hash, offsets[bestIndex], bestLengthCount.length, bestLengthCount.count, bestIndices);

        //chat("    Best match %s %s", hash, offsets);

        return match;
    }
    uint compareTokenStreams(uint offset1, uint offset2) {
        //chat("    comparing stream offsets (%s,%s)", offset1, offset2);
        static import maths;
        static import std.math;

        auto diff = std.math.abs(offset1.as!int-offset2.as!int);

        auto maxLength = maths.min(
            tokens.length-offset1,
            tokens.length-offset2,
            diff);

        // chat("    diff          = %s", diff);
        // chat("    maxLength     = %s", maxLength);

        auto p1 = tokens.ptr+offset1;
        auto p2 = tokens.ptr+offset2;
        auto i  = 0;

        for(i = 0; i<maxLength; i++) {
            //chat("%s %s", *p1, *p2);
            if(*p1 != *p2) break;
            p1++;
            p2++;
        }
        //chat("    match length  = %s", i);
        // chat("    match        = %s", tokens[offset1..offset1+i+1]);
        // chat("    match        = %s", tokens[offset2..offset2+i+1]);

        return i;
    }
    void readAllTokens() {
        tokens.length = input.length;

        foreach(i; 0..tokens.length) {
            tokens[i] = input.read!ubyte;
        }
        numUniqueTokens = 256;

        chat("Loaded %s tokens", tokens.length);
    }
}
