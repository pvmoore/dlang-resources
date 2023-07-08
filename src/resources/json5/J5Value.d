module resources.json5.J5Value;

import resources.json5.all;

private enum Kind {
    OBJECT,
    NUMBER,
    STRING,
    ARRAY,
    NULL,
    BOOLEAN,
    COMMENT
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
abstract class J5Value {
public:
    abstract void serialise(StringBuffer buf, string prefix = "");
protected:
    Kind kind;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Object : J5Value {
public:
    J5Value[string] map;

    bool isEmpty() { return map.length ==0; }

    J5Value get(string key) { return map.get(key, null); }

    override bool opEquals(Object other) {
        J5Object otherObject = other.as!J5Object;
        if(otherObject is null || map.length != otherObject.map.length) return false;

        foreach(e; map.byKeyValue()) {
            J5Value v = otherObject.get(e.key);
            if(v is null || e.value != v) return false;
        }

        return true;
    }

    override void serialise(StringBuffer buf, string prefix) {
        buf.add("{");
        string prefix2 = prefix ~ "  ";
        foreach(e; map.byKeyValue()) {
            buf.add("\n").add(prefix2);
            buf.add(e.key).add(" : ");
            e.value.serialise(buf, prefix2);
        }
        if(!isEmpty()) buf.add("\n").add(prefix);
        buf.add("}");
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Array : J5Value {
public:
    J5Array[] array;

    uint length() { return array.length.as!uint; }

    override bool opEquals(Object other) {
        J5Array otherArray = other.as!J5Array;
        if(otherArray is null || otherArray.length() != length()) return false;

        foreach(i; 0..length()) {
            if(array[i] != otherArray.array[i]) return false;
        }

        return true;
    }

    override void serialise(StringBuffer buf, string prefix) {
        buf.add("[");
        prefix ~= "  ";

        foreach(i, v; array) {
            if(i>0) buf.add(",");
            buf.add("\n").add(prefix);
            v.serialise(buf, prefix);
        }
        buf.add("]");
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Number : J5Value {
public:
    string value;

    bool opEquals(string other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Number && other.as!J5Number.value == value;
    }
    override ulong toHash() {
        return value.toHash();
    }

    override void serialise(StringBuffer buf, string prefix) {
        buf.add(value);
    }
    override string toString() {
        return value;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5String : J5Value {
public:
    string value;

    this(string value) {
        this.value = value;
    }

    bool opEquals(string other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5String && other.as!J5String.value == value;
    }
    override ulong toHash() {
        return value.toHash();
    }
    override void serialise(StringBuffer buf, string prefix) {
        buf.add(value);
    }
    override string toString() {
        return value;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Null : J5Value {
public:
    override bool opEquals(Object other) {
        return other.isA!J5Null;
    }
    override ulong toHash() {
        return 0;
    }
    override void serialise(StringBuffer buf, string prefix) {
        buf.add("null");
    }
    override string toString() {
        return "null";
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Boolean : J5Value {
public:
    bool value;

    this(bool value) {
        this.value = value;
    }

    bool opEquals(bool other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Boolean && other.as!J5Boolean.value == value;
    }
    override ulong toHash() {
        return value ? 1 : 0;
    }
    override void serialise(StringBuffer buf, string prefix) {
        buf.add("%s", value);
    }
    override string toString() {
        return value ? "true" : "false";
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Comment : J5Value {
public:
    string value;

    this(string value) {
        this.value = value;
    }

    bool opEquals(string other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Comment && other.as!J5Comment.value == value;
    }
    override ulong toHash() {
        return value.toHash();
    }

    override void serialise(StringBuffer buf, string prefix) {
        buf.add(value);
    }
    override string toString() {
        return value;
    }
}