module resources.json5.all;

public:

import std.format   : format;
import std.string   : startsWith, toLower;
import std.file     : read;
import std.typecons : Tuple, tuple;
import std.conv     : to;
import std.stdio    : writefln;

import resources.json5;

import resources.json5.J5Lexer;
import resources.json5.J5Parser;
import resources.json5.J5Token;

import common            : contains, isA, as, isOneOf, StringBuffer, toHash;
import common.containers : Stack;

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}
bool isHexDigit(char c) {
    return isDigit(c) || isBetween(c, 'a', 'f') || isBetween(c, 'A', 'F'); 
}
bool isBetween(char c, char a, char b) {
    return c >= a && c <= b;
}
bool isInteger(string s) {
    int n = 0;
    if(s.length > 0) {
        if(s[0] == '-' || s[0] == '+') n++;
    }
    if(isHexadecimal(s)) return true;
    foreach(i; n..s.length) {
        if(!isDigit(s[i])) return false;
    }
    return true;
}
bool isHexadecimal(string s) {
    if(s.length < 3) return false;
    if(s[0] != '0' || (s[1] != 'x' && s[1] != 'X')) return false;
    foreach(c; s[2..$]) {
        if(!isHexDigit(c)) return false; 
    } 
    return true;
}
