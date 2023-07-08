module test_json5;

import resources.json5;

import common : StringBuffer, as, isA;

import std.stdio    : writefln;


void testJson5() {
    writefln("Testing JSON5");

    auto buf = new StringBuffer();
    {
        auto j = JSON5.fromFile("testdata2/json5/empty.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object1.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object2.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.get("key").as!J5String == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object2a.json5");
        buf.clear();
        j.serialise(buf);
        writefln("%s", buf.toString());

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.get("key").as!J5String == "value");
    }

 

}