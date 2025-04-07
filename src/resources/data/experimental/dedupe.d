module resources.data.experimental.dedupe;

import resources.all;
import common;
import std;

/**
 * Simple encoder where the longest duplicate string of tokens is found and replaced.
 * This is done repeatedly until the longest duplicate string is less than 3 tokens.
 * The matches are dumped out at the end.
 * The idea is that the remaining tokens (which will now be > 8 bit tokens) will need to be entropy coded
 * along with the list of matches. 
 *
 * A variation would be to operate like a LZ encoder but the longest string is encoded each time instead of
 * processing the data as a stream. This obviously has some downsides.
 *
 * Note that this is a work in progress experiment and is not complete.
 */
final class DeDupe {

    static struct Match {
        uint pos;
        uint len;
    }
    
    void run(string filename) {
        import std.file : read;
        ubyte[] bytes = cast(ubyte[])read(filename);
        //ubyte[] bytes = [cast(ubyte)1,0,0,0,0, 0,0, 1,0,0,0,0, 1,0,0,0,0, 2];

        data.length = bytes.length;
        writefln("length = %s", bytes.length);

        // Copy the ubyte array to a uint array
        foreach(i; 0..bytes.length) {
            data[i] = bytes[i];
        }

        // Run iterations until the max dupe is only length 2
        foreach(i; 0..uint.max) {
            Tuple!(uint,uint) tup = iteration();
            uint len = tup[0];
            uint count = tup[1];
            writefln("After iteration %s :: match len = %s, count = %s, data.length = %s", 
                i, len, count, data.length);
            if(len < 3) break;
        }

        writefln("Finished");

        //writefln("data = %s", data);

        writefln("%s matches:", matches.length);
        foreach(i, m; matches) {
            writefln(" [%s] %s", i+256, m);
        }
    }
    uint[] data;
    Match[] matches;

    Tuple!(uint,uint) iteration() {
        //writefln("Iteration ############################");
        //writefln("data.length = %s", data.length);
        //writefln("matches = %s", matches);
        //writefln("data = %s", data);

        uint bestMatchIndex;
        Match bestMatch = findBestMatch(bestMatchIndex);

        uint numReplacements = updateData(bestMatchIndex, bestMatch);
        return tuple(bestMatch.len, numReplacements);
    }
    uint updateData(uint index, Match match) {
        //writefln("best @ %s = %s", index, match);
        //writefln("%s", data);

        uint numReplacements = 1;

        replaceMatch(match);

        // Look for other instances of match and replace them too
        uint from = match.pos+1;
        while(true) {
            int j = findMatch(index, from, match.len);
            if(j==-1) break;

            replaceMatch(Match(j, match.len));
            numReplacements++;
            from = j+1;
            break;
        }
        matches ~= Match(index, match.len);
        return numReplacements;
    }
    void replaceMatch(Match match) {
        import core.stdc.string : memmove;

        //writefln("before: %s", data);

        data[match.pos] = 256 + matches.length.as!uint;

        auto remainder = data.length - (match.pos+match.len);

        memmove(data.ptr+match.pos+1, data.ptr+match.pos+match.len, remainder*4);
        data.length -= match.len-1;

        //writefln("after:  %s", data);
    }
    int findMatch(uint a, uint b, uint len) {
        //writefln("findMatch(%s,%s,%s)", a, b, len);
        foreach(i; b..(data.length-len+1).as!uint) {
            if(isMatch(a, i, len)) return i;
        }
        return -1;
    }
    bool isMatch(uint a, uint b, uint len) {
        //writefln("isMatch(%s,%s,%s)", a,b,len);
        foreach(i; 0..len) {
            if(data[a+i] != data[b+i]) return false;
        }
        return true;
    }
    Match findBestMatch(ref uint bestMatchIndex) {
        import common.utils : getOrAdd;
        Match bestMatch;
        uint[][uint] hash;    // each pair contains a list of indexes

        // calculate hash of pairs
        foreach(i; 0..data.length.as!uint-1) {
            uint pair = data[i] | (data[i+1] << 16);
            uint[] list;
            auto p = hash.getOrAdd(pair, list);
            *p ~= i;
            //writefln("[%s,%s] = %s", pair&0xffff, pair>>>16, *p);
        } 
        // writefln("data = %s", data);
        // writefln("hash = {");
        // foreach(e; hash.byKeyValue) {
        //     writefln("  (%s,%s) = %s", e.key&0xffff, e.key>>>16, e.value);
        // }
        // writefln("}");

        foreach(i; 0..data.length.as!uint-1) {
            uint pair = data[i] | (data[i+1] << 16);
            auto p = pair in hash;
            assert(p);

            uint[] list = *p;

            if(list.length > 1) {
                //writefln("checking [%s] pair = [%s,%s] p = %s", i, pair&0xff, pair>>>8, *p);

                // Look through the list of pairs
                foreach(j; 0..list.length) {
                    uint pos = list[j];
                    if(i == pos) continue;

                    uint len = getMatchLength(i, pos);
                    if(len > bestMatch.len) {
                        bestMatch.len  = len;
                        bestMatch.pos  = pos;
                        bestMatchIndex = i;
                        //writefln("   match @%s = %s len %s", i, pos, len);
                    }
                }
            }
        }

        return bestMatch;
    }
    /**
     * Check strings starting at a and b. Return the length of the match
     */
    uint getMatchLength(uint a, uint b) {
        if(a > b) { uint c = a; a = b; b = c; }
        assert(a<b);

        uint bStart = b;
        uint len = 0;
        while(a < bStart && b < data.length) {
            if(data[a++] != data[b++]) break;
            len++;
        }
        return len;
    }
}
