module test_json5;

import resources.json5;

import common : StringBuffer, as, isA;

import std.stdio    : writefln;

void testJson5() {
    writefln("Testing JSON5");
    testJson5Object();
    testJson5Array();
}

private:

void testJson5Object() {
    auto buf = new StringBuffer();
    {
        auto j = JSON5.fromFile("testdata2/json5/object/empty.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object1.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.get("key") == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2a.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.get("key") == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.hasKey("key2"));
        assert(j.as!J5Object.get("key") == "value");
        assert(j.as!J5Object.get("key2") == "value2");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3a.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.hasKey("key2"));
        assert(j.as!J5Object.get("key") == "value");
        assert(j.as!J5Object.get("key2") == "value2");
    }
}

void testJson5Array() {
    auto buf = new StringBuffer();
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array1.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Array);
        assert(j.as!J5Array.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array2.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Array);
        assert(!j.as!J5Array.isEmpty());
        assert(j.as!J5Array.length() == 1);
        assert(j.as!J5Array[0] == "hello");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array3.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Array);
        assert(!j.as!J5Array.isEmpty());
        assert(j.as!J5Array.length() == 2);
        assert(j.as!J5Array[0] == "hello");
        assert(j.as!J5Array[1] == 3);
    }
}