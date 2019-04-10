module resources.algorithms.deflate.Symbol;

struct Symbol {
    uint symbol;        // symbol 
    uint value;         // base value
    uint numExtraBits;  // num bits used in extra
    uint extra;         // extra bits data
}