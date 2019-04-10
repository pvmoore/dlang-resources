module resources.algorithms.deflate.Distances;

import resources.algorithms.deflate;
import resources.all;

/** 
 *  The distance tree contains 32 symbols:
 *  
 *  Symbol |     Distance | Extra bits
 * --------|--------------|------------
 *       0 |            1 | 0
 *       1 |            2 | 0
 *       2 |            3 | 0
 *       3 |            4 | 0
 *       4 |         5..6 | 1 
 *       5 |         7..8 | 1
 *       6 |        9..12 | 2
 *       7 |       13..16 | 2
 *       8 |       17..24 | 3
 *       9 |       25..32 | 3
 *      10 |       33..48 | 4 
 *      11 |       49..64 | 4
 *      12 |       65..96 | 5
 *      13 |      97..128 | 5 
 *      14 |     129..192 | 6
 *      15 |     193..256 | 6
 *      16 |     257..384 | 7
 *      17 |     385..512 | 7
 *      18 |     513..768 | 8
 *      19 |    769..1024 | 8
 *      20 |   1025..1536 | 9 
 *      21 |   1537..2048 | 9
 *      22 |   2049..3072 | 10
 *      23 |   3073..4096 | 10
 *      24 |   4097..6144 | 11
 *      25 |   6145..8192 | 11 
 *      26 |  8193..12288 | 12 
 *      27 | 12289..16384 | 12 
 *      28 | 16385..24576 | 13
 *      29 | 24577..32768 | 13
 *      30 | Unused
 *      31 | Unused
 */
final class Distances {
public:
    static uint decode(uint code, BitReader r) {
        switch(code) {
            case 0: return 1;
            case 1: return 2;
            case 2: return 3;
            case 3: return 4;
            case 4: return 5 + r.read(1);
            case 5: return 7 + r.read(1);
            case 6: return 9 + r.read(2);
            case 7: return 13 + r.read(2);
            case 8: return 17 + r.read(3);
            case 9: return 25 + r.read(3);
            case 10: return 33 + r.read(4);
            case 11: return 49 + r.read(4);
            case 12: return 65 + r.read(5);
            case 13: return 97 + r.read(5);
            case 14: return 129 + r.read(6);
            case 15: return 193 + r.read(6);
            case 16: return 257 + r.read(7);
            case 17: return 385 + r.read(7);
            case 18: return 513 + r.read(8);
            case 19: return 769 + r.read(8);
            case 20: return 1025 + r.read(9);
            case 21: return 1537 + r.read(9);
            case 22: return 2049 + r.read(10);
            case 23: return 3073 + r.read(10);
            case 24: return 4097 + r.read(11);
            case 25: return 6145 + r.read(11);
            case 26: return 8193 + r.read(12);
            case 27: return 12289 + r.read(12);
            case 28: return 16385 + r.read(13);
            case 29: return 24577 + r.read(13);
            default:
                throw new Error("Error in compressed data");
        }
    }
    /**
     *  Convert distance to symbol.
     */
    static Symbol encode(uint distance) {
        switch(distance) {
            case 1 : return Symbol(0,distance,0,0);
            case 2 : return Symbol(1,distance,0,0);
            case 3 : return Symbol(2,distance,0,0);
            case 4 : return Symbol(3,distance,0,0);

            case 5:..case 6 : return Symbol(4, 5, 1, distance-5);
            case 7:..case 8 : return Symbol(5, 7, 1, distance-7);

            case 9:..case 12  : return Symbol(6, 9,  2, distance-9);
            case 13:..case 16 : return Symbol(7, 13, 2, distance-13);

            case 17:..case 24 : return Symbol(8, 17, 3, distance-17);
            case 25:..case 32 : return Symbol(9, 25, 3, distance-25);

            case 33:..case 48 : return Symbol(10, 33, 4, distance-33);
            case 49:..case 64 : return Symbol(11, 49, 4, distance-49);

            case 65:..case 96  : return Symbol(12, 65, 5, distance-65);
            case 97:..case 128 : return Symbol(13, 97, 5, distance-97);

            case 129:..case 192 : return Symbol(14, 129, 6, distance-129);
            case 193:..case 256 : return Symbol(15, 193, 6, distance-193);

            case 257:..case 384 : return Symbol(16, 257, 7, distance-257);
            case 385:..case 512 : return Symbol(17, 385, 7, distance-385);

            case 513:..case 768  : return Symbol(18, 513, 8, distance-513);
            case 769:..case 1024 : return Symbol(19, 769, 8, distance-769);

            case 0:
                throw new Error("Invalid distance value: %s".format(distance));

            default: 
                break;
        }
        if(distance >= 1025 && distance <= 1536) return Symbol(20, 1025, 9, distance-1025);
        if(distance >= 1537 && distance <= 2048) return Symbol(21, 1537, 9, distance-1537);

        if(distance >= 2049 && distance <= 3072) return Symbol(22, 2049, 10, distance-2049);
        if(distance >= 3073 && distance <= 4096) return Symbol(23, 3073, 10, distance-3073);

        if(distance >= 4097 && distance <= 6144) return Symbol(24, 4097, 11, distance-4097);
        if(distance >= 6145 && distance <= 8192) return Symbol(25, 6145, 11, distance-6145);

        if(distance >= 8193   && distance <= 12_288) return Symbol(26, 8193,   12, distance-8193);
        if(distance >= 12_289 && distance <= 16_384) return Symbol(27, 12_289, 12, distance-12_289);

        if(distance >= 16_385 && distance <= 24_576) return Symbol(28, 16_385, 13, distance-16_385);
        if(distance >= 24_577 && distance <= 32_768) return Symbol(29, 24_577, 13, distance-24_577);

        throw new Error("Invalid distance value: %s".format(distance));
    }
}