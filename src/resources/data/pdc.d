module resources.data.pdc;
/**
 *  Peter's Data Compression.
 */
import resources.all;

final class PDC {

    this(string filename) {
        this.srcFilename  = filename;
        this.destFilename = "testdata/test0.pdc";
        this.reader       = new FileByteReader(srcFilename);
        this.writer       = new FileBitWriter(destFilename);
        encode();
    }

private:
    const ulong[] PRIMES = [7,11,13,17,19,23,29];
    align(1) static struct Entry { align(1):
        ulong leftHash;     // may point to any entry
        ubyte rightHash;    // always points to 0-255 ubyte
    }
    string srcFilename;
    string destFilename;
    File file;
    Entry[ulong] entries;
    ByteReader reader;
    FileBitWriter writer;
    double bitsWritten;

    string dumpHash(ulong hash) {
        if(hash<256) return "%s".format(cast(char)hash);
        return dumpEntry(entries[hash]);
    }
    string dumpEntry(Entry e) {
        string s = e.leftHash<256? "%s".format(cast(char)e.leftHash) :
                   dumpEntry(entries[e.leftHash]);
        return s ~ "%s".format(cast(char)e.rightHash);
    }

    ulong getHash(ulong a, ulong b) {
        ulong h = 5381;
        h   = ((h << 13)) + a;
        h  ^= ((h << 17)) + b;
        // reserve the 0-255 range
        if(h<256) h += 256;
        return h;
    }
    void encode() {
        file.open(srcFilename, "rb");
        scope(exit) file.close();
        chat("Encoding file '%s' length %s", srcFilename, file.size);

        // todo - handle length==0

        Entry* findEntry(ulong leftHash, ubyte byt, ref ulong hash) {
            chat("  findEntry('%s','%s')", dumpHash(leftHash), cast(char)byt);
            hash = getHash(leftHash, byt);

            return hash in entries;
        }

        bitsWritten = 0;
        double bitsRequired = 8;
        ubyte curr = reader.read!ubyte;

        while(!reader.eof) {
            chat("----");
            chat("'%s'", cast(char)curr);
            // assume basic entry
            ulong leftHash = curr;

            // look for better
            Entry* entry;
            ulong hash;
            bool consumeLast = true;
            while(!reader.eof) {
                consumeLast = true;
                curr = reader.read!ubyte;
                chat("  '%s'", cast(char)curr);
                entry = findEntry(leftHash, curr, hash);
                if(entry is null) {
                    break;
                }
                chat("  Found '%s'", dumpEntry(*entry));
                leftHash = hash;
                consumeLast = false;
            }
            //chat("  consumeLast=%s", consumeLast);

            chat("  Writing '%s'", dumpHash(leftHash));
            // todo - use Huffman rather than bitsRequired bits
            //writer.write(b, bitsRequired);
            bitsWritten += bitsRequired;

            if(reader.eof) {
                if(consumeLast) {
                    chat("  Writing last char '%s'", dumpHash(curr));
                    // todo - use Huffman rather than bitsRequired bits
                    //writer.write(b, bitsRequired);
                    bitsWritten += bitsRequired;
                }
            } else {
                // add the latest hash
                auto newEntry = Entry(leftHash, curr);
                chat("  new entry '%s' (%s)", dumpEntry(newEntry), hash);

                entries[hash] = newEntry;
                bitsRequired = entropyBits(1, cast(int)entries.length+256);
                chat("  bitsRequired = %s", bitsRequired);
            }
        }
        chat("Finished writing %s bits", bitsWritten);
    }
}

