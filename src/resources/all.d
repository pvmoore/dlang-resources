module resources.all;

public:

import resources;

import common : as, dbg, expect, flushConsole, makeLowPriorityQueue, startsWith, todo,
				Array, ArrayByteWriter,
				BitReader, FileBitReader, ByteReader, FileByteReader,
				BitWriter, FileBitWriter, ByteWriter, FileByteWriter,
				From, StringBuffer;

import logging : log, flushLog;
import maths;

import std.array    			: Appender, appender, split;
import std.format   			: format;
import std.conv     			: to;
import std.math     			: abs;
import std.stdio    			: writefln, File, SEEK_CUR;
import std.file     			: exists, getSize;
import std.path     			: baseName, extension;
import std.string   			: toLower;
import std.range    			: appender, array;
import std.regex    			: matchFirst;
import std.typecons 			: tuple;
import std.algorithm.iteration  : each, map;
import std.algorithm.sorting    : sort;

enum chatty = true;

void chat(A...)(string fmt, A args) {
	static if(chatty) {
	    log(fmt, args);
	    flushLog();
		writefln(fmt, args);
	}
}
