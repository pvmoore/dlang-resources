module resources.algorithms.lz77.LZ77;

import resources.all;
import core.bitop : popcnt;

enum LZ77Strategy {
    NAIVE,            // Scan the history for each match
                      // (Minimum match length is 2)

    LARGE_HASH,       // Use a large hash of 2-byte keys to find matches.
                      // This currently does not prune old keys so will grow larger as the input size increases.
                      // (Minimum match length is 2)

    HASH_AND_LINKS_2, // Use a small 2-sequence hash of keys and a circular buffer of links to previous matches
                      // This uses a fast array lookup of 64k entries to find the most recent match so has a minimum
                      // memory footprint of ~512k.
                      // (Minimum match length is 2)

    HASH_AND_LINKS_3, // Use a small 3-sequence hash of keys and a circular buffer of links to previous matches
                      // (Minimum match length is 3)
}

/**
 *  https://en.wikipedia.org/wiki/LZ77_and_LZ78
 *
 *
 */
final class LZ77(LZ77Strategy STRATEGY) {
public:
    const uint windowSize;
    const uint maxMatchLength;
    const uint maxLiteralsLength;
    alias MatchCallback = uint delegate(ulong index, uint distance, uint length);
    alias LiteralsCallback = void delegate(ulong index, ubyte[] literals);

    LiteralsCallback literalsCallback;
    MatchCallback matchCallback;

    this(uint windowSize,
         uint maxMatchLength,
         uint maxLiteralsLength, 
         MatchCallback matchCallback, 
         LiteralsCallback literalsCallback) 
    {
        assert(popcnt(windowSize) == 1, "Window size must be a power of 2");
        assert(windowSize >= 2, "Window size must be 2 or higher");
        assert(maxMatchLength >= 2, "Max match length must be 2 or higher");
        assert(maxLiteralsLength >= 2, "Max literals length must be 2 or higher");
        assert(maxMatchLength <= windowSize, "Max match length must be less than or equal to window size");
        assert(maxLiteralsLength <= windowSize, "Max literals length must be less than or equal to window size");

        this.windowSize        = windowSize;
        this.maxMatchLength    = maxMatchLength;
        this.maxLiteralsLength = maxLiteralsLength;
        this.matchCallback     = matchCallback;
        this.literalsCallback  = literalsCallback;
    }
    void encodeFile(string filename) {
        encode(new FileByteReader(filename));
    }
    void encode(ubyte[] bytes) {
        encode(new ByteReader(bytes));
    }
    void encode(ByteReader reader) {
        // Exit if there is nothing to do
        if(reader.length == 0) return;
        
        this.window = new Window!STRATEGY(windowSize, maxMatchLength, reader);

        ubyte[] literals;
        literals.reserve(maxLiteralsLength);

        // The first byte must be a literal
        literals ~= window.headValue();
        window.shift();

        while(window.hasMore()) {

            auto match = window.find();
            if(match.length > 1) {
                writeLiterals(literals);
                uint matchConsumed = writeMatch(match);
                window.shift(matchConsumed);

            } else {
                literals ~= window.headValue();
                window.shift();
                if(literals.length == maxLiteralsLength) {
                    writeLiterals(literals);
                }
            }
        }
        writeLiterals(literals);
    }
private:
    Window!STRATEGY window;

    uint writeMatch(Match match) {
        return matchCallback(window.position(), match.distance, match.length);
    }
    void writeLiterals(ref ubyte[] literals) {
        if(literals.length > 0) {
            literalsCallback(window.position() - literals.length, literals);
            literals.length = 0;
        }
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

struct Match {
    enum Match NONE = Match();
    uint distance;
    uint length;

    string toString() {
        if(length == 0) return "NO_MATCH";
        return "Match(distance:%s, length:%s)".format(distance, length);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
final class Window(LZ77Strategy STRATEGY) {
    const uint MASK;
    const uint windowSize;
    const uint maxMatchLength;
    const ulong fileLength;
    ByteReader reader;
    uint start;
    uint end;
    uint head;
    uint bufferSize;
    uint historySize;
    ulong currentFilePos;
    ubyte[] buffer;

    this(uint windowSize, uint maxMatchLength, ByteReader reader) {
        this.windowSize = windowSize;
        this.maxMatchLength = maxMatchLength;
        this.reader = reader;
        this.MASK = windowSize*2-1;
        this.buffer.length = windowSize*2;
        this.fileLength = reader.length;

        this.preRead();

        static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_2) {
            links.length = windowSize*2;
            links[] = uint.max;
            currentKey = headValue();
            fastHash.length = ushort.max+1;
            fastHash[] = ulong.max;  
        }
        static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_3) {
            links.length = windowSize*2;
            links[] = uint.max;
            currentKey = (headValue() << 8) | peekHead(1);
        }
    }

    bool hasMore() {
        return currentFilePos < fileLength;
    }
    ulong position() {
        return currentFilePos;
    }
    ubyte headValue() {
        return buffer[head];
    }
    ubyte peekHead(int offset) { 
        return buffer[(head + offset) & MASK]; 
    }
    ubyte peekHistory(int offset) { 
        return buffer[(start + offset) & MASK]; 
    }
    void shift(int count = 1) {
        foreach(i; 0..count) {

            static if(STRATEGY == LZ77Strategy.LARGE_HASH) {
                ushort key = (headValue() << 8) | peekHead(1);

                if(auto ptr = key in largeHash) {
                    // Replace a stale value in the list if possible
                    uint left = (currentFilePos - historySize).as!uint;
                    bool staleFound = false;
                    foreach(j, pos; *ptr) {
                        if(pos < left) {
                            (*ptr)[j] = currentFilePos;
                            staleFound = true;
                            break;
                        }
                    }
                    // Add to the end of the list if no stale value was found
                    if(!staleFound) {
                        *ptr ~= currentFilePos;
                    }

                } else {
                    largeHash[key] ~= currentFilePos;
                }
            }
            static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_2) {
                currentKey <<= 8;
                currentKey |= peekHead(1);

                ulong prevPos = fastHash[currentKey];
                if(prevPos != ulong.max) {
                    // Set the back link
                    links[head] = (currentFilePos - prevPos).as!uint;
                } else {
                    links[head] = uint.max;
                }
                // Replace the hash value with the most recent position
                fastHash[currentKey] = currentFilePos;

                /+
                if(auto ptr = currentKey in smallHash) {
                    // Set the back link
                    ulong prevPos = *ptr;
                    links[head] = (currentFilePos - prevPos).as!uint;

                    // Replace the hash value with the most recent position
                    *ptr = currentFilePos;
                } else {
                    // This key has not been seen before. Add it to the hash
                    smallHash[currentKey] = currentFilePos;
                    links[head] = uint.max;
                }
                +/
            }
            static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_3) {
                // currentKey <<= 8;
                // currentKey &= 0xffffff;
                // currentKey |= peekHead(1);

                currentKey = (headValue() << 16) | (peekHead(1) << 8) | peekHead(2);

                if(auto ptr = currentKey in smallHash) {
                    // Set the back link
                    ulong prevPos = *ptr;
                    links[head] = (currentFilePos - prevPos).as!uint;

                    // Replace the hash value with the most recent position
                    *ptr = currentFilePos;
                } else {
                    // This key has not been seen before. Add it to the hash
                    smallHash[currentKey] = currentFilePos;
                    links[head] = uint.max;
                }
            }

            head = (head+1) & MASK;

            if(historySize < windowSize) {
                historySize++;
            } else {
                // Discard the oldest byte
                start = (start+1) & MASK;
                bufferSize--;
            }
            
            if(!reader.eof()) {
                buffer[end] = reader.read!ubyte;
                end = (end+1) & MASK;
                bufferSize++;
            } 
            currentFilePos++;
        }
    }
    Match find() {
        final switch(STRATEGY) {
            case LZ77Strategy.NAIVE: return findNaive();
            case LZ77Strategy.LARGE_HASH: return findLargeHash();
            case LZ77Strategy.HASH_AND_LINKS_2: return findHashAndLinks2();
            case LZ77Strategy.HASH_AND_LINKS_3: return findHashAndLinks3();
        }
    }

    override string toString() {
        string s = "[";
        foreach(i; 0..bufferSize) {
            if(i==historySize) s ~= "┆ ";
            s ~= "%s ".format(peekHistory(i).as!char);
        }
        return s ~ "] head = %s (%s)".format(head, headValue().as!char);
    }
private:
    /** Read up to 'windowSize' bytes into the buffer */ 
    void preRead() {
        auto len = minOf(reader.length, windowSize);
        // todo - read len bytes in one go because len <= windowSize
        foreach(i; 0..len) {
            buffer[end] = reader.read!ubyte;
            end = (end+1) & MASK;
            bufferSize++;
        }
    }
    Match evaluateMatch(uint length, uint maxLength, uint startIndex) {
        for(; length<maxLength; length++) {
            if(peekHead(length) != peekHistory(startIndex+length)) break;
        }
        return Match(historySize-startIndex-1, length);
    }

//──────────────────────────────────────────────────────────────────────────────────────────────────    
static if(STRATEGY == LZ77Strategy.NAIVE) {    
    /** Naive search for the longest match (minimum match is 2 bytes) */
    Match findNaive() {
        uint maxLength = minOf(maxMatchLength, fileLength - currentFilePos).as!uint;
        if(maxLength < 2) return Match.NONE;

        Match bestMatch = Match.NONE;
        ubyte first = headValue();

        foreach(i; 0..historySize) {
            if(peekHistory(i) == first) {
                // We have found a potential starting point. Now see how long the match is
                Match m = evaluateMatch(1, maxLength, i);
                if(m.length >= bestMatch.length) {
                    bestMatch = m;
                } 
            }
        }
        return bestMatch;
    }
} else {
    Match findNaive() {
        return Match.NONE;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
static if(STRATEGY == LZ77Strategy.LARGE_HASH) {
    /**
     * Find the longest match using a large hash table to store locations of 2-byte sequences within the history window
     */
    Match findLargeHash() {
        uint maxLength = minOf(maxMatchLength, fileLength - currentFilePos).as!uint;
        if(maxLength < 2) return Match.NONE;

        enum DUMP = false;

        static if(DUMP) writefln("FIND (index = %s, maxLength = %s)", position(), maxLength);
        Match bestMatch = Match.NONE;
        ushort key = (headValue() << 8) | peekHead(1);
        ulong left = currentFilePos - historySize;
        static if(DUMP) {
            writefln(" key = '%s%s' 0x%04x", headValue().as!char, peekHead(1).as!char, key);
            writefln(" left = %s", left);
            writefln(" hash = %s", dumpLargeHash());
        }
        if(auto ptr = key in largeHash) {
            static if(DUMP) writefln("  list = %s", *ptr);
            foreach(ulong pos; *ptr) {
                static if(DUMP) writefln("  pos = %s", pos);
                if(pos < left) {
                    // This entry has fallen out of the window
                    static if(DUMP) writefln("  stale");
                    continue;
                }
                // The entry is inside the window. See how long the match is
                Match m = evaluateMatch(2, maxLength, (pos-left).as!uint);
                static if(DUMP) writefln("  match = %s", m);
                if(m.length > bestMatch.length) {
                    bestMatch = m;
                } else if(m.length == bestMatch.length) {
                    // If the match is the same length, prefer the one that is closer to the head
                    if(m.distance < bestMatch.distance) {
                        bestMatch = m;
                    }
                }
            }
        } 

        return bestMatch;
    }
    ulong[][ushort] largeHash;  // key = 2-byte sequence, value = list of positions

    string dumpLargeHash() {
        string s;
        foreach(e; largeHash.byKeyValue) {
            s ~= format("{'%s%s' = %s} ", (e.key>>8).as!char, (e.key&0xff).as!char, e.value);
        }
        return s;
    }
} else {
    Match findLargeHash() {
        return Match.NONE;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_2) {
    Match findHashAndLinks2() {
        uint maxLength = minOf(maxMatchLength, fileLength - currentFilePos).as!uint;
        if(maxLength < 2) return Match.NONE;

        enum DUMP = false;
        
        Match bestMatch = Match.NONE;
        ushort key = (headValue() << 8) | peekHead(1);
        long left = currentFilePos - historySize;

        static if(DUMP) {
            writefln("FIND (index = %s, maxLength = %s)", position(), maxLength);
            writefln("  key  = '%s%s' 0x%04x", headValue().as!char, peekHead(1).as!char, key);
            writefln("  left = %s", left);
            writefln("  hash = %s", dumpSmallHash());
        }

        long pos = fastHash[key];
        if(pos != ulong.max) {

        //if(auto ptr = key in smallHash) {
        //    long pos = *ptr;
            static if(DUMP) writefln("  pos  = %s", pos);
            if(pos < left) {
                // The most recent entry has fallen out of the window which means there cannot be a match
                static if(DUMP) writefln("  stale");
                return Match.NONE;
            } 

            // The most recent entry is still within the window. Check it and follow the links backwards
            bestMatch = evaluateMatch(2, maxLength, (pos-left).as!uint);
            static if(DUMP) writefln("  match = %s", bestMatch);

            if(bestMatch.length == maxLength) {
                // Exit here because we can't do better
                return bestMatch;
            }

            static if(DUMP) writefln("  ** following back links");
            // Follow the link backwards until we go past the left side of the window
            while(true) {
                auto linkslot = pos-left;
                auto backLink = links[(start + linkslot) & MASK];
                auto newPos   = pos-backLink;
                static if(DUMP) {
                    writefln("   linkslot = %s", linkslot);
                    writefln("   backLink = %s", backLink == uint.max ? "NO_LINK" : format("%s", backLink));
                    writefln("   newPos   = %s", newPos);
                }
                if(newPos < left) {
                    static if(DUMP) writefln("  ** reached left side of window");
                    break;
                }

                pos = newPos;
                Match m = evaluateMatch(2, maxLength, (pos-left).as!uint);
                static if(DUMP) writefln("  match = %s", m);

                // Replace match if it is longer, keep most recent if length is the same
                if(m.length > bestMatch.length) {
                    bestMatch = m;
                } 
            }
        }

        return bestMatch;
    }
    //ulong[ushort] smallHash;    // key = 2-byte sequence, value = most recent position (could change this to uint distance)
    ulong[] fastHash;           // Flat 65536 element hash of 2-byte sequences (64k*8 = 512k)
    uint[] links;               // circular buffer of back links
    ushort currentKey;   
    // string dumpSmallHash() {
    //     string s;
    //     foreach(e; smallHash.byKeyValue) {
    //         s ~= format("{'%s%s' = %s} ", (e.key>>8).as!char, (e.key&0xff).as!char, e.value);
    //     }
    //     return s;
    // }
} else {
    Match findHashAndLinks2() {
        return Match.NONE;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
static if(STRATEGY == LZ77Strategy.HASH_AND_LINKS_3) {
    Match findHashAndLinks3() {
        uint maxLength = minOf(maxMatchLength, fileLength - currentFilePos).as!uint;
        if(maxLength < 3) return Match.NONE;

        enum DUMP = false;
        
        Match bestMatch = Match.NONE;
        uint key = (headValue() << 16) | (peekHead(1) << 8) | peekHead(2);
        long left = currentFilePos - historySize;

        static if(DUMP) {
            writefln("FIND (index = %s, maxLength = %s)", position(), maxLength);
            writefln("  key  = '%s%s%s' 0x%06x", headValue().as!char, peekHead(1).as!char,peekHead(2).as!char, key);
            writefln("  left = %s", left);
            writefln("  hash = %s", dumpSmallHash());
        }

        if(auto ptr = key in smallHash) {
            long pos = *ptr;
            static if(DUMP) writefln("  pos  = %s", pos);
            if(pos < left) {
                // The most recent entry has fallen out of the window which means there cannot be a match
                static if(DUMP) writefln("  stale");
                return Match.NONE;
            } 

            // The most recent entry is still within the window. Check it and follow the links backwards
            bestMatch = evaluateMatch(2, maxLength, (pos-left).as!uint);
            static if(DUMP) writefln("  match = %s", bestMatch);

            if(bestMatch.length == maxLength) {
                // Exit here because we can't do better
                return bestMatch;
            }

            static if(DUMP) writefln("  ** following back links");
            // Follow the link backwards until we go past the left side of the window
            while(true) {
                auto linkslot = pos-left;
                auto backLink = links[(start + linkslot) & MASK];
                auto newPos   = pos-backLink;
                static if(DUMP) {
                    writefln("   linkslot = %s", linkslot);
                    writefln("   backLink = %s", backLink == uint.max ? "NO_LINK" : format("%s", backLink));
                    writefln("   newPos   = %s", newPos);
                }
                if(newPos < left) {
                    static if(DUMP) writefln("  ** reached left side of window");
                    break;
                }

                pos = newPos;
                Match m = evaluateMatch(3, maxLength, (pos-left).as!uint);
                static if(DUMP) writefln("  match = %s", m);

                // Replace match if it is longer, keep most recent if length is the same
                if(m.length > bestMatch.length) {
                    bestMatch = m;
                } 
            }
        }

        return bestMatch;
    }
    ulong[uint] smallHash;   // key = 3-byte sequence, value = most recent position
    uint[] links;          
    uint currentKey;

    string dumpSmallHash() {
        string s;
        foreach(e; smallHash.byKeyValue) {
            s ~= format("{'%s%s%s' = %s} ", ((e.key>>16)&0xff).as!char, ((e.key>>8)&0xff).as!char, (e.key&0xff).as!char, e.value);
        }
        return s;
    }
} else {
    Match findHashAndLinks3() {
        return Match.NONE;
    }
}

}
