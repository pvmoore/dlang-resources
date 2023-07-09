module test_json5;

import resources.json5;

import common : StringBuffer, as, isA, throwIfNotEqual;

import std.stdio    : writefln;

void testJson5() {
    writefln("Testing JSON5");
    testJson5Object();
    testJson5Array();
    testJson5Number();
    testJson5String();
    testJson5Boolean();
    testJson5Null();
    testJson5Comment();
}

private:

void testJson5Object() {
    {
        auto j = JSON5.fromFile("testdata2/json5/object/empty.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(j.as!J5Object.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.get("key") == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2a.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.get("key") == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.hasKey("key2"));
        assert(j.as!J5Object.get("key") == "value");
        assert(j.as!J5Object.get("key2") == "value2");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3a.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Object);
        assert(!j.as!J5Object.isEmpty());
        assert(j.as!J5Object.hasKey("key"));
        assert(j.as!J5Object.hasKey("key2"));
        assert(j.as!J5Object.get("key") == "value");
        assert(j.as!J5Object.get("key2") == "value2");
    }
}

void testJson5Array() {
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Array);
        assert(j.as!J5Array.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array2.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Array);
        assert(!j.as!J5Array.isEmpty());
        assert(j.as!J5Array.length() == 1);
        assert(j.as!J5Array[0] == "hello");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array3.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Array);
        assert(!j.as!J5Array.isEmpty());
        assert(j.as!J5Array.length() == 2);
        assert(j.as!J5Array[0] == "hello");
        assert(j.as!J5Array[1] == 3);
    }
}

void testJson5Number() {
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Number);
        assert(j == 4);
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number2.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Number);
        assert(j == 3.14);
    }
}

void testJson5String() {
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5String);
        assert(j == "string");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string2.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5String);
        assert(j == "string");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string3.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5String);
        assert(j == "one\\\\ntwo");
    }
}

void testJson5Boolean() {
    {
        auto j = JSON5.fromFile("testdata2/json5/boolean/boolean1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Boolean);
        assert(j == true);
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/boolean/boolean2.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Boolean);
        assert(j == false);
    }
}

void testJson5Null() {
    {
        auto j = JSON5.fromFile("testdata2/json5/null/null1.json5");
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Null);
    }
}

void testJson5Comment() {
    {
        auto j = JSON5.fromFile("testdata2/json5/comment/comment1.json5", true);
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Comment);
        assert(j == "// This is a comment");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/comment/comment2.json5", true);
        writefln("%s", JSON5.stringify(j));

        assert(j.isA!J5Comment);
        assert(j == "/*\r\n This is a comment\r\n*/");
    }
}