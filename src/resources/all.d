module resources.all;

public:

import resources;

import common : expect, Array, ByteReader, FileBitWriter;
import logging : log, flushLog;
import maths;

import std.array    : Appender, appender;
import std.format   : format;
import std.conv     : to;
import std.math     : abs;
import std.stdio    : writefln, File;
import std.file     : exists, getSize;
import std.path     : baseName, extension;
import std.string   : toLower;
import std.range    : appender;
import std.regex    : matchFirst;
import std.algorithm.iteration : each;

__gshared const bool chatty = false;

void chat(A...)(lazy string fmt, lazy A args) {
	if(chatty) {
	    log(fmt, args);
	    flushLog();
	}
}
