module resources.algorithms.deflate.Lengths;

import resources.algorithms.deflate;
import resources.all;

/**
 *  The literal and length tree contains 288 symbols:
 *
 *    Symbol | Literal
 * ----------|--------------------------
 *    0..255 | Literal ubyte value
 *       256 | End of block
 *           |
 *           | Length   | Extra bits
 * ----------|----------|----------------
 *       257 |        3 | 0
 *       258 |        4 | 0
 *       259 |        5 | 0
 *       260 |        6 | 0
 *       261 |        7 | 0
 *       262 |        8 | 0
 *       263 |        9 | 0
 *       264 |       10 | 0
 *       265 |   11..12 | 1
 *       266 |   13..14 | 1
 *       267 |   15..16 | 1
 *       268 |   17..18 | 1
 *       269 |   19..22 | 2 
 *       270 |   23..26 | 2
 *       271 |   27..30 | 2
 *       272 |   31..34 | 2
 *       273 |   35..42 | 3 
 *       274 |   43..50 | 3 
 *       275 |   51..58 | 3 
 *       276 |   59..66 | 3 
 *       277 |   67..82 | 4 
 *       278 |   83..98 | 4 
 *       279 |  99..114 | 4 
 *       280 | 115..130 | 4 
 *       281 | 131..162 | 5 -
 *       282 | 163..194 | 5 -
 *       283 | 195..226 | 5 -
 *       284 | 227..257 | 5 -
 *       285 |      258 | 0
 *  286,287  | Unused
 */
final class Lengths {
public:
    static uint decode(uint code, BitReader r) {
        switch(code) {
            case 257: return 3;
            case 258: return 4;
            case 259: return 5;
            case 260: return 6;
            case 261: return 7;
            case 262: return 8;
            case 263: return 9;
            case 264: return 10;
            case 265: return 11 + r.read(1);
            case 266: return 13 + r.read(1);
            case 267: return 15 + r.read(1);
            case 268: return 17 + r.read(1);
            case 269: return 19 + r.read(2);
            case 270: return 23 + r.read(2);
            case 271: return 27 + r.read(2);
            case 272: return 31 + r.read(2);
            case 273: return 35 + r.read(3);
            case 274: return 43 + r.read(3);
            case 275: return 51 + r.read(3);
            case 276: return 59 + r.read(3);
            case 277: return 67 + r.read(4);
            case 278: return 83 + r.read(4);
            case 279: return 99 + r.read(4);
            case 280: return 115 + r.read(4);
            case 281: return 131 + r.read(5);
            case 282: return 163 + r.read(5);
            case 283: return 195 + r.read(5);
            case 284: return 227 + r.read(5);
            case 285: return 258;
            default:
                throw new Error("Error in compressed data");
        }
    }
    static Symbol encodeLiteral(uint lit) {
        return Symbol(lit, lit, 0,0);
    }
    static Symbol encodeLength(uint len) {
        switch(len) {
            case 3: return Symbol(257, 3, 0,0);
            case 4: return Symbol(258, 4, 0,0);
            case 5: return Symbol(259, 5, 0,0);
            case 6: return Symbol(260, 6, 0,0);
            case 7: return Symbol(261, 7, 0,0);
            case 8: return Symbol(262, 8, 0,0);
            case 9: return Symbol(263, 9, 0,0);
            case 10: return Symbol(264, 10, 0,0);

            case 11:..case 12: return Symbol(265, 11, 1, len-11);
            case 13:..case 14: return Symbol(266, 13, 1, len-13);
            case 15:..case 16: return Symbol(267, 15, 1, len-15);
            case 17:..case 18: return Symbol(268, 17, 1, len-17);

            case 19:..case 22: return Symbol(269, 19, 2, len-19);
            case 23:..case 26: return Symbol(270, 23, 2, len-23);
            case 27:..case 30: return Symbol(271, 27, 2, len-27);
            case 31:..case 34: return Symbol(272, 31, 2, len-31);

            case 35:..case 42: return Symbol(273, 35, 3, len-35);
            case 43:..case 50: return Symbol(274, 43, 3, len-43);
            case 51:..case 58: return Symbol(275, 51, 3, len-51);
            case 59:..case 66: return Symbol(276, 59, 3, len-59);

            case 67:..case 82:   return Symbol(277, 67, 4, len-67);
            case 83:..case 98:   return Symbol(278, 83, 4, len-83);
            case 99:..case 114:  return Symbol(279, 99, 4, len-99);
            case 115:..case 130: return Symbol(280, 115, 4, len-115);

            case 131:..case 162: return Symbol(281, 131, 5, len-131);
            case 163:..case 194: return Symbol(282, 163, 5, len-163);
            case 195:..case 226: return Symbol(283, 195, 5, len-195);
            case 227:..case 257: return Symbol(284, 227, 5, len-227);

            case 258: return Symbol(285, 258, 0, 0);

            default:
               throw new Error("Invalid length value: %s".format(len));
        }
    }
}