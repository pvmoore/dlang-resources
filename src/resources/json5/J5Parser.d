module resources.json5.J5Parser;

import resources.json5.all;

import std.string : toLower;

final class J5Parser {
public:
    this(J5Token[] tokens, string src) {
        this.tokens = new Tokens(tokens, src);
    }
    J5Value parse(bool includeComments) {
        // // If there are no tokens return empty J5Object
        if(tokens.eof()) {
            return new J5Object();
        }
        return parseValue();
    }
private:
    Tokens tokens;

    J5Value parseValue() {
        J5Value v;
        switch(tokens.kind()) with(J5TokenKind) {
            case LCURLY:
                v = parseObject();
                break;
            case LSQUARE:
                v = parseArray();
                break;
            case NUMBER:
                v = parseNumber();
                break;
            case ID: 
                switch(tokens.value()) {
                    case "null": 
                        v = J5NULL;
                        tokens.next();
                        break;
                    case "true":
                        v = J5TRUE;
                        tokens.next();
                        break;
                    case "false":
                        v = J5FALSE;
                        tokens.next();
                        break;
                    case "NaN":
                        v = J5NAN;
                        tokens.next();
                        break;
                    case "Infinity":
                        v = J5INFINITY;
                        tokens.next();
                        break;
                    default:
                        syntaxError(); 
                        break;
                }
                break;
            case STRING:
                v = parseString();
                break;    
            default:
                syntaxError();
                break;
        }
        if(v is null) {
            return new J5Object();
        }
        return v;
    }
    J5Object parseObject() {
        // only one or more [id : value] allowed here
        auto obj = new J5Object();

        // {
        tokens.next();

        // Members
        while(tokens.kind() != J5TokenKind.RCURLY) {
            auto kv = parseObjectMember();
            obj.add(kv.key, kv.value);

            // optional comma
            if(tokens.kind() == J5TokenKind.COMMA) tokens.next();
        }

        // }
        tokens.next();

        return obj;
    }
    J5Array parseArray() {
        // zero or more of (Number, Boolean, Null, Array, Object)
        auto array = new J5Array();

        // [
        tokens.next();    

        while(tokens.kind() != J5TokenKind.RSQUARE) {
            array.add(parseValue());

            // optional comma
            if(tokens.kind() == J5TokenKind.COMMA) tokens.next();
        }

        // ]    
        tokens.next();

        return array;
    }
    /**
     * key : value
     */
    ObjectMember parseObjectMember() {
        // key
        string key = tokens.value();
        tokens.next();
        if(key[0]=='\"' || key[0]=='\'') {
            key = key[1..$-1];
        }

        // :
        if(tokens.kind() != J5TokenKind.COLON) syntaxError();
        tokens.next();

        // value
        return ObjectMember(key, parseValue());
    }
    /**
     * Infinity, NaN, NumericLiteral
     */
    J5Number parseNumber() {
        string value = tokens.value();
        tokens.next();
        if(value.length==1) {
            return J5NUMBERS[value[0]-'0'];
        }
        return new J5Number(value);
    }
    /**
     * "value" or 'value'
     */
    J5String parseString() {
        auto s = new J5String(tokens.value());
        tokens.next();
        return s;
    }
    void syntaxError(string msg = null) {
        auto t = tokens.get();
        if(!msg) {
            msg = "Unexpected token %s".format(t);
        }
        throw new Exception("Json5 syntax error at position %s, line %s, column %s: %s".format(
            t.pos, t.line, t.column, msg));
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

__gshared {
    bool[string] RESERVED_IDENTIFIERS;

    static this() {
        RESERVED_IDENTIFIERS = [
            "break" : true,
            "do" : true,
            "instanceof" : true,
            "typeof" : true,
            "case" : true,
            "else" : true,
            "new" : true,
            "var" : true,
            "catch" : true,
            "finally" : true,
            "return" : true,
            "void" : true,
            "continue" : true,
            "for" : true,
            "switch" : true,
            "while" : true,
            "debugger" : true,
            "function" : true,
            "this" : true,
            "with" : true,
            "default" : true,
            "if" : true,
            "throw" : true,
            "delete" : true,
            "in" : true,
            "try" : true
        ];
    }
}

struct ObjectMember {
    string key; 
    J5Value value;
}

final class Tokens {
    J5Token[] tokens;
    string src;
    int pos;

    this(J5Token[] tokens, string src) {
        this.tokens = tokens;
        this.src = src;
        this.pos = 0;
    }
    bool eof() {
        return pos >= tokens.length;
    }
    void next(int count = 1) {
        pos += count;
    }
    J5Token get(int offset = 0) {
        return pos+offset < tokens.length ? tokens[pos+offset] : NO_TOKEN;
    }
    J5TokenKind kind(int offset = 0) {
        return get(offset).kind;
    }
    string value(int offset = 0) {
        return get(offset).text;
    }
}