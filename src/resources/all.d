module resources.all;

public:

import resources;

import common : as, expect, flushConsole, todo, makeLowPriorityQueue, startsWith,
				Array, ArrayByteWriter,
				From,
				BitReader, FileBitReader,
				ByteReader, FileByteReader,
				BitWriter, FileBitWriter,
				ByteWriter, FileByteWriter,
				StringBuffer;
import logging : log, flushLog;
import maths;

import std.array    : Appender, appender;
import std.format   : format;
import std.conv     : to;
import std.math     : abs;
import std.stdio    : writefln, File, SEEK_CUR;
import std.file     : exists, getSize;
import std.path     : baseName, extension;
import std.string   : toLower;
import std.range    : appender;
import std.regex    : matchFirst;
import std.algorithm.iteration : each, map;

__gshared const bool chatty = true;

void chat(A...)(lazy string fmt, lazy A args) {
	static  if(chatty) {
	    log(fmt, args);
		writefln(fmt, args);
	    flushLog();
	}
}
