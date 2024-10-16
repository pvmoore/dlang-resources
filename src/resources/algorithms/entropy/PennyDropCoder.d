module resources.algorithms.entropy.PennyDropCoder;

 import resources.all;

/**
 *           0 | 1
 *             |   0  | 1 
 *  |----------|------|---|
 *
 * Create model of frequencies (ordered by size of frequency, with larger frequencies to the left). 
 * eg.
 *  frequencies = [a = 10, b = 3, c = 2, d = 1], num = 4, scale = 16, value = d
 *  Initial state:
 *      [aaaaaaaaaabbbccd] 
 *      [        |       ] min = 0 mid = 8 max = 16
 *
 *  [round 1] stats = {num = 4, numToLeft = 1, isRight = true, nextMin = 10} 
 *  Drop bit = 1
 *                [bbbccd] 
 *                [   |  ] min = 10 mid = 13 max = 16
 *
 *  [round 2] stats = {num = 3, numToLeft = 1, isRight = true, nextMin = 13} 
 *  Drop bit = 1
 *                   [ccd] 
 *                   [ | ] min = 13 mid = 14 max = 16
 *
 *  [round 3] stats = {num = 2, numToLeft = 1, isRight = true, nextMin = 14} 
 *  Drop bit = 1
 *                   [d] 
 *                   [|] min = 14 mid = 15 max = 16
 *  [round 4]
 *  num = 1 so the value is implied
 */
struct Stats { 
    uint num;               // number of unique values in the range
    uint numToLeftOfCentre; // number of unique values to the left of mid
    bool isRight;           // false if the value is on the left, true if on the right

    uint nextMin;           // the adjusted min value. this will usually be mid but it might be higher
                            // if numToLeftOfCentre was 1 and isRight = true
}

final static class Model {
    ulong[] frequencies;
    ulong scale;

    Stats getStats(ulong min, ulong mid, ulong max, uint value) {
        Stats s;

        // generate stats

        // update the model

        return s;
    }
}

final class PennyDropCoder {
private:
    Model model;
public:
    this(Model model) {
        this.model = model;
    }
    void encode(BitWriter w, BitWriter w0, uint value) {
        ulong min = 0;
        ulong max = model.scale;

        while(true) {
            ulong mid  = (min+max) / 2;
            auto stats = model.getStats(min, mid, max, value); 
            if(stats.num==1) {
                // Only 1 possibility. Infer the bit and this code is done
                return;
            } else {
                
                // Go left or right 

                if(stats.numToLeftOfCentre==1) {

                    // Example: The code on the left extends over to the right hand side which means the likelihood 
                    // of the next bit being a 0 is greater than 50%. We can use this info to compress these special
                    // bits further later on. Write them to a different stream for further compression later.
                    // |000000000|000000111|

                    // Note that we could write to more than one special stream. We know that the probability of
                    // the bit being 0 is (frequency of left side value / total frequency) * 100% which will
                    // always be 50% or greater. We can write the 50% -> 60% bits to one stream, 60% -> 70% to
                    // another stream etc...
                    w0.write(stats.isRight, 1);

                } else {
                    // Write this bit to the standard stream since we can't compress this further later. 
                    // Should be an approximately random 0 or 1.
                    w.write(stats.isRight, 1);
                }

                if(stats.isRight) {
                    min = stats.nextMin;
                } else {
                    max = mid;
                }
            }
        }
    }
    int decode(BitReader r) {
        return 0;
    }
}
