module resources.json5.J5Token;

import resources.json5.all;

__gshared J5Token NO_TOKEN = J5Token(J5TokenKind.NONE);

struct J5Token {
    J5TokenKind kind;
    int pos;
    int length;
    int line;
    int column;
    string text;    // This is mostly a substring of the original src
                    // but can be a newly allocated string if the value
                    // contained a '\' continuation   

    string toString(string src) {
        if(lengthOf(kind)==0) {
            return "J5Token(%s %s, pos:%s len:%s line:%s)".format(stringOf(kind), text, pos, text.length, line);
        }
        return toString();
    }
    string toString() {
        return "J5Token(%s, pos:%s len:%s line:%s)".format(kind, pos, length, line);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
enum J5TokenKind {
    NONE,
    ID,
    COMMENT,
    STRING,
    NUMBER,

    DQUOTE,
    SQUOTE,
    COMMA,
    COLON,
    LCURLY,
    RCURLY,
    LSQUARE,
    RSQUARE
}

string stringOf(J5TokenKind t) {
    final switch(t) with(J5TokenKind) {
        case NONE:
        case ID:
        case COMMENT:
        case STRING:
        case NUMBER:
            return "%s".format(t);
        case DQUOTE: return "\"";
        case SQUOTE: return "'";
        case COMMA: return ",";
        case COLON: return ":";
        case LCURLY: return "{";
        case RCURLY: return "}";
        case LSQUARE: return "[";
        case RSQUARE: return "]";
    }
}

int lengthOf(J5TokenKind t) {
    final switch(t) with(J5TokenKind) {
        case NONE:
        case ID:
        case COMMENT:
        case STRING:
        case NUMBER:
            return 0;
        case DQUOTE:
        case SQUOTE:
        case COMMA:
        case COLON:
        case LCURLY:
        case RCURLY:
        case LSQUARE:
        case RSQUARE:
            return 1;
    }
}