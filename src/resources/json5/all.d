module resources.json5.all;

public:

import std.format : format;
import std.string : startsWith;
import std.file   : read;

import resources.json5;

import resources.json5.J5Lexer;
import resources.json5.J5Parser;
import resources.json5.J5Token;

import common : isA, as, isOneOf, StringBuffer, toHash;

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}
