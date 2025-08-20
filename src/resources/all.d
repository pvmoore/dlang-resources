module resources.all;

public:

import resources;

import common  			 : StringBuffer;
import common.containers : makeLowPriorityQueue;
import common.io 		 : ArrayByteWriter, 
				   		   BitReader, FileBitReader, ByteReader, FileByteReader,
				   		   BitWriter, FileBitWriter, ByteWriter, FileByteWriter,
				   		   flushConsole;
import common.utils 	 : as, isA, isOneOf, From, expect,  isSet, isUnset, startsWith, throwIf, toArray, toString, 
						   todo, containsKey;

import logging 			 : log, flushLog;

import maths;

import std.array    			: Appender, appender, split;
import std.format   			: format;
import std.conv     			: to;
import std.math     			: abs;
import std.stdio    			: writef, writefln, File, SEEK_CUR;
import std.file     			: exists, getSize;
import std.path     			: baseName, extension;
import std.string   			: splitLines, strip, toLower;
import std.range    			: appender, array, iota;
import std.regex    			: matchFirst;
import std.typecons 			: tuple, Tuple, Nullable, nullable;
import std.algorithm  			: each, map, sort;

enum chatty = false;

void chat(A...)(string fmt, A args) {
	static if(chatty) {
	    log(fmt, args);
	    flushLog();
		writefln(fmt, args);
	}
}
