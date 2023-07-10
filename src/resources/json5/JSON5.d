module resources.json5.Json5;

import resources.json5.all;

final class JSON5 {
public:
    J5Value root;

    static J5Value fromFile(string filename, bool includeComments = false) {
        JSON5 j = new JSON5(cast(string)read(filename), includeComments);
        return j.root;
    }
    static J5Value fromString(string str, bool includeComments = false) {
        JSON5 j = new JSON5(str, includeComments);
        return j.root;
    }
    static string stringify(J5Value root, bool pretty = false) {
        return new J5Serialiser(pretty).stringify(root);
    }
private:
    string src;
    J5Token[] tokens;

    this(string src, bool includeComments) {
        this.src = src;
        auto lexer = new J5Lexer();
        this.tokens = lexer.getTokens(src);

        // writefln("tokens:");
        // foreach(t; tokens) {
        //     writefln("  %s", t.toString(src));
        // }

        auto parser = new J5Parser(tokens, src);
        this.root = parser.parse(includeComments);
    }
}