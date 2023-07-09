module resources.json5.J5Lexer;

import resources.json5.all;

/**
 * https://spec.json5.org/#grammar
 */
final class J5Lexer {
public:
    J5Token[] getTokens(string src) {
        this.src = src;
        this.pos = 0;
        this.line = 0;
        this.lineStart = 0;
        this.tokenStart = 0;
        this.tokens.length = 0;

        while(pos < src.length) {
            char ch = peek();

            if(ch<33) {
                addToken();
                skipWhitespace();
            } else switch(ch) {
                case '/':
                    if(peek(1)=='/') {
                        addToken();
                        lineComment();
                        break;
                    } else if(peek(1)=='*') {
                        addToken();
                        multiLineComment();
                        break;
                    }
                    syntaxError("Unexpected character '/'");
                    break;    
                case '\'':
                    addToken();
                    quoted('\'');
                    break;
                case '"':
                    addToken();
                    quoted('"');
                    break;
                case ':':
                    addToken(J5TokenKind.COLON);
                    break;
                case ',':
                    addToken(J5TokenKind.COMMA);
                    break;
                case '{':
                    addToken(J5TokenKind.LCURLY);
                    break;
                case '}':
                    addToken(J5TokenKind.RCURLY);
                    break;
                case '[':
                    addToken(J5TokenKind.LSQUARE);
                    break;
                case ']':
                    addToken(J5TokenKind.RSQUARE);
                    break;
                default:
                    pos++;
                    break;
            }
        }
        addToken();

        return tokens;
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    string src;
    int pos;
    int line;
    int lineStart;
    int tokenStart;
    J5Token[] tokens;
    char[] tempChars;

    char peek(int offset = 0) {
        if(pos+offset>=src.length) return 0;
        return src[pos+offset];
    }
    void syntaxError(string msg) {
        throw new Exception("Json5 syntax error at position %s, line %s, column %s: %s".format(
            pos, line, tokenStart-lineStart, msg));
    }
    bool isEol() {
        return peek(0).isOneOf(10, 13);
    }
    void eol() {
        // can be 13,10 or just 10
        if(peek(0)==13) pos++;
        if(peek(0)==10) pos++;
        line++;
        lineStart = pos;
    }
    void skipWhitespace() {
        while(pos<src.length) {
            if(isEol()) {
                eol();
            } else if(peek(0) < 33) {
                pos++;
            } else {
                break;
            }
        }
        tokenStart = pos;
    }
    void lineComment() {
        pos += 2;
        while(pos<src.length) {
            if(isEol()) {
                break;
            }
            pos++;
        }
        tokenStart = pos;
    }
    void multiLineComment() {
        pos += 2;
        while(pos<src.length) {
            if(isEol()) {
                eol();
            } else if(peek(0)=='*' && peek(1)=='/') {
                pos+=2;
                tokenStart = pos;
                return;
            } else {
                pos++;
            }
        }
        syntaxError("EOF looking for */");
    }
    void quoted(char quote) {
        // 'string'
        // "string"
        pos++;
        tempChars.length = 0;
        while(pos<src.length) {
            char ch = peek(0);
            if(ch=='\\' && peek(1)==quote) {
                pos+=2;
                tempChars ~= '\\';
                tempChars ~= quote;
            } else if(ch==quote) {
                pos++;
                addToken(tempChars.idup);
                return;
            } else if(ch=='\\' && peek(1).isOneOf(10,13)) {
                pos++;
                eol();
            } else {
                tempChars ~= ch;
                pos++;
            }
        }
        syntaxError("EOF looking for " ~ quote);
    }                   

    J5TokenKind determineKind(string s) {
        if(s.length==0) return J5TokenKind.ID;
        if(isDigit(s[0])) return J5TokenKind.NUMBER;
        if(s.length>1) {
            if(s[0]=='-' && isDigit(s[1])) return J5TokenKind.NUMBER;
            if(s[0]=='+' && isDigit(s[1])) return J5TokenKind.NUMBER;
            if(s[0]=='.' && isDigit(s[1])) return J5TokenKind.NUMBER;
        }
        return J5TokenKind.ID;
    }
    void addToken(string text) {
        int column = tokenStart-lineStart;
        tokens ~= J5Token(J5TokenKind.STRING, tokenStart, text.length.as!int, line, column, text);
        tokenStart = pos;
    }
    void addToken(J5TokenKind k = J5TokenKind.NONE) {
        if(tokenStart < pos) {
            string value = src[tokenStart..pos];
            J5TokenKind tk2 = determineKind(value);
            int column = tokenStart-lineStart;
            tokens ~= J5Token(tk2, tokenStart, pos-tokenStart, line, column, value);
        }
        if(k != J5TokenKind.NONE) {
            int column = pos-lineStart;
            int len = lengthOf(k);
            tokens ~= J5Token(k, pos, len, line, column);
            pos += len;
        }
        tokenStart = pos;
    }
}