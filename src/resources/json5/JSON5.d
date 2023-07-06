module resources.json5.Json5;

import resources.json5.all;

final class JSON5 {
public:
    J5Value root;

    static J5Value fromFile(string filename) {
        JSON5 j = new JSON5(cast(string)read(filename));
        return j.root;
    }
    static J5Value fromString(string str) {
        JSON5 j = new JSON5(str);
        return j.root;
    }
private:
    string src;
    J5Token[] tokens;

    this(string src) {
        this.src = src;
        auto lexer = new J5Lexer();
        this.tokens = lexer.getTokens(src);

        import std.stdio;

        writefln("tokens:");
        foreach(t; tokens) {
            writefln("  %s", t.toString(src));
        }

        auto parser = new J5Parser(tokens, src);
        this.root = parser.getRoot();
    }
}