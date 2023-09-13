module test_json5;

import resources.json5;

import common : StringBuffer, as, isA, throwIfNotEqual;

import std.stdio  : writefln;
import std.format : format;

void testJson5() {
    writefln("Testing JSON5");
    testJson5Object();
    testJson5Array();
    testJson5Number();
    testJson5String();
    testJson5Boolean();
    testJson5Null();
}

private:

void testJson5Object() {
    {
        auto j = JSON5.fromFile("testdata2/json5/object/empty.json5");
        expectStringify(j, "{}");

        assert(j.isA!J5Object);
        assert(j.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object1.json5");
        expectStringify(j, "{}");

        assert(j.isA!J5Object);
        assert(j.isEmpty());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2.json5");
        expectStringify(j, "{\"key\":\"value\"}");

        assert(j.isA!J5Object);
        assert(!j.isEmpty());
        assert(j.hasKey("key"));
        assert(j["key"] == "value");

        auto value = j["key"].toString();
        assert(value == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object2a.json5");
        expectStringify(j, "{\"key\":\"value\"}");

        assert(j.isA!J5Object);
        assert(!j.isEmpty());
        assert(j.hasKey("key"));
        assert(j["key"] == "value");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3.json5");
        expectStringify(j, "{\"key\":\"value\",\"key2\":\"value2\"}");

        assert(j.isA!J5Object);
        assert(!j.isEmpty());
        assert(j.hasKey("key"));
        assert(j.hasKey("key2"));
        assert(j["key"] == "value");
        assert(j["key2"] == "value2");

        foreach(k, v; j.byKeyValue()) {
            writefln("%s = %s", k, v);
        }
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object3a.json5");
        expectStringify(j, "{\"key\":\"value\",\"key2\":\"value2\"}");
        
        assert(j.isA!J5Object);
        assert(!j.isEmpty());
        assert(j.hasKey("key"));
        assert(j.hasKey("key2"));
        assert(j["key"] == "value");
        assert(j["key2"] == "value2");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/object/object4.json5");
        expectStringify(j, "{\"key\":[1,2,3]}");
        
        assert(j.isA!J5Object);
        assert(!j.isEmpty());
        assert(j.hasKey("key"));
        assert(j["key"].isA!J5Array);
        assert(j["key"][0] == 1);
        assert(j["key"][1] == 2);
        assert(j["key"][2] == 3);
    }
}

void testJson5Array() {
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array1.json5");
        expectStringify(j, "[]");

        assert(j.isA!J5Array);
        assert(j.isEmpty());
        assert(!j.hasKey("key"));
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array2.json5");
        expectStringify(j, "[\"hello\"]");

        assert(j.isA!J5Array);
        assert(!j.isEmpty());
        assert(j.length() == 1);
        assert(j[0] == "hello");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/array/array3.json5");
        expectStringify(j, "[\"hello\",3]");

        assert(j.isA!J5Array);
        assert(!j.isEmpty());
        assert(j.length() == 2);
        assert(j[0] == "hello");
        assert(j[1] == 3);

        foreach(v; j.as!J5Array) {
            writefln("%s", v);
        }
        foreach(i, v; j.as!J5Array) {
            writefln("[%s] %s", i, v);
        }
    }
}

void testJson5Number() {
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number1.json5");
        expectStringify(j, "4");

        assert(j.isA!J5Number);
        assert(j == 4);
        assert(j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number2.json5");
        expectStringify(j, "3.14");

        assert(j.isA!J5Number);
        assert(j == 3.14);
        assert(!j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number3.json5");
        expectStringify(j, "0xffff");

        assert(j.isA!J5Number);
        assert(j == 0xffff);
        assert(j == "0xffff");
        assert(j == "0XFFFF");
        assert(j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number4.json5");
        expectStringify(j, "-3.14");

        assert(j.isA!J5Number);
        assert(j == -3.14);
        assert(!j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number5.json5");
        expectStringify(j, "NaN");

        assert(j.isA!J5Number);
        assert(j.as!J5Number.isNaN());
        assert(!j.as!J5Number.isInfinity());
        assert(!j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number6.json5");
        expectStringify(j, "Infinity");

        assert(j.isA!J5Number);
        assert(!j.as!J5Number.isNaN());
        assert(j.as!J5Number.isInfinity());
        assert(!j.as!J5Number.isInteger());
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number7.json5");
        expectStringify(j, ".34");

        assert(j.isA!J5Number);
        assert(j == 0.34);
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/number/number8.json5");
        expectStringify(j, "5.");

        assert(j.isA!J5Number);
        assert(j == 5.0);
    }
}

void testJson5String() {
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string1.json5");
        expectStringify(j, "\"string\"");

        assert(j.isA!J5String);
        assert(!j.isEmpty());
        assert(j.length()==6);
        assert(j == "string");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string2.json5");
        expectStringify(j, "'string'");

        assert(j.isA!J5String);
        assert(j == "string");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string3.json5");
        expectStringify(j, "\"one\\\\ntwo\"");

        assert(j.isA!J5String);
        assert(j == "one\\\\ntwo");
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/string/string4.json5");
        expectStringify(j, "'string \" thing'");

        assert(j.isA!J5String);
        assert(j == "string \" thing");
    }
}

void testJson5Boolean() {
    {
        auto j = JSON5.fromFile("testdata2/json5/boolean/boolean1.json5");
        expectStringify(j, "true");

        assert(j.isA!J5Boolean);
        assert(!j.isEmpty());
        assert(j.length()==1);
        assert(j == true);
    }
    {
        auto j = JSON5.fromFile("testdata2/json5/boolean/boolean2.json5");
        expectStringify(j, "false");

        assert(j.isA!J5Boolean);
        assert(j == false);
    }
}

void testJson5Null() {
    {
        auto j = JSON5.fromFile("testdata2/json5/null/null1.json5");
        expectStringify(j, "null");

        assert(j.isA!J5Null);
        assert(j.isEmpty());
        assert(j.length()==0);
    }
}

void expectStringify(J5Value j, string s) {
    string stringified = JSON5.stringify(j);
    writefln("Stringify: %s", stringified);
    writefln("Pretty:\n%s", JSON5.stringify(j, true));
    throwIfNotEqual(stringified, s);
}
