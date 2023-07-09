module resources.json5.J5Value;

import resources.json5.all;

__gshared {
J5Null J5NULL = new J5Null();
J5Boolean J5TRUE = new J5Boolean(true);
J5Boolean J5FALSE = new J5Boolean(false);
J5Number J5INFINITY = new J5Number("Infinity");
J5Number J5NAN = new J5Number("NaN");
J5Number[10] J5NUMBERS = [
    new J5Number("0"),
    new J5Number("1"),
    new J5Number("2"),
    new J5Number("3"),
    new J5Number("4"),
    new J5Number("5"),
    new J5Number("6"),
    new J5Number("7"),
    new J5Number("8"),
    new J5Number("9")
];
}

private enum Kind {
    OBJECT,
    ARRAY,
    STRING,
    NUMBER,
    BOOLEAN,
    NULL
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
abstract class J5Value {
public:
    abstract void serialise(StringBuffer buf, string prefix = "");
    
    final bool isObject() { return this.isA!J5Object; }
    final bool isArray() { return this.isA!J5Array; }
    final bool isNull() { return this.isA!J5Null; }
    final bool isString() { return this.isA!J5String; }
    final bool isNumber() { return this.isA!J5Number; }
    final bool isBoolean() { return this.isA!J5Boolean; }

    bool opEquals(string other) {
        return this.isA!J5String && this.as!J5String.opEquals(other);
    }
    bool opEquals(long other) {
        return this.isA!J5Number && this.as!J5Number.opEquals(other);
    }  
    bool opEquals(double other) {
        return this.isA!J5Number && this.as!J5Number.opEquals(other);
    }
    bool opEquals(bool other) {
        if(isNumber()) return this.as!J5Number.opEquals(other.as!int);
        return isBoolean() && this.as!J5Boolean.value == other;
    }
    // Only useful for J5Array
    J5Value opIndex(int index) {
        if(isArray()) {
            return this.as!J5Array.array[index];
        }
        return J5NULL;
    }
    // Only useful for J5Object
    J5Value opIndex(string key) {
        if(isObject()) {
            return this.as!J5Object.map.get(key, J5NULL);
        }
        return J5NULL;
    }
    // Only makes sense for J5Object and J5Array
    bool isEmpty() {
        if(isObject()) return this.as!J5Object.isEmpty();
        if(isArray()) return this.as!J5Array.isEmpty();
        if(isString()) return this.as!J5String.value.length == 0;
        return isNull();
    }
    uint length() {
        if(isObject()) return this.as!J5Object.map.length.as!uint;
        if(isArray()) return this.as!J5Array.length();
        if(isString()) return this.as!J5String.value.length.as!uint;
        if(isNull()) return 0;
        return 1;
    }
protected:
    Kind kind;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Object : J5Value {
public:
    this() {}
    this(J5Value[string] map) {
        this.map = map;
    }

    override bool isEmpty() { return map.length ==0; }
    bool hasKey(string key) { return (key in map) !is null; }

    override J5Value opIndex(string key) { return map.get(key, null); }

    alias opEquals = J5Value.opEquals;
    override bool opEquals(Object other) {
        J5Object otherObject = other.as!J5Object;
        if(otherObject is null || map.length != otherObject.map.length) return false;

        foreach(e; map.byKeyValue()) {
            J5Value v = otherObject.map.get(e.key, null);
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
private:
    J5Value[string] map;    
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Array : J5Value {
public: 
    this(J5Value[] array) {
        this.array = array;
    }

    override bool isEmpty() { return array.length==0; }
    override uint length() { return array.length.as!uint; }
    override J5Value opIndex(int i) { return array[i]; }

    alias opEquals = J5Value.opEquals;
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
        string prefix2 = prefix ~ "  ";

        foreach(i, v; array) {
            buf.add("\n").add(prefix2);
            v.serialise(buf, prefix2);
        }
        if(!isEmpty()) buf.add("\n").add(prefix);
        buf.add("]");
    }
private:
    J5Value[] array;    
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Number : J5Value {
public:
    string value;

    this(string value) {
        this.isHex = isHexadecimal(value);
        if(isHex) {
            this.value = value.toLower();
        } else {
            this.value = value;
        }
    }

    bool isInteger() { return this !is J5NAN && this !is J5INFINITY && .isInteger(value); }
    bool isNaN() { return this is J5NAN; }
    bool isInfinity() { return this is J5INFINITY; }

    alias opEquals = J5Value.opEquals;
    override bool opEquals(long other) {
        if(isHex) return value[2..$].to!long(16) == other;
        return isInteger() && value.to!long == other;
    }
    override bool opEquals(double other) {
        return value.to!double == other;
    }
    override bool opEquals(string other) {
        if(isHex) return value == other.toLower();
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Number && other.as!J5Number.value == value;
    }

    override void serialise(StringBuffer buf, string prefix) {
        buf.add(value);
    }
    override string toString() {
        return value;
    }
private:
    bool isHex;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5String : J5Value {
public:
    string value;

    this(string value) {
        this.value = value;
    }

    alias opEquals = J5Value.opEquals;
    override bool opEquals(string other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5String && other.as!J5String.value == value;
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
    alias opEquals = J5Value.opEquals;
    override bool opEquals(Object other) {
        return other.isA!J5Null;
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

    alias opEquals = J5Value.opEquals;
    override bool opEquals(bool other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Boolean && other.as!J5Boolean.value == value;
    }
    override void serialise(StringBuffer buf, string prefix) {
        buf.add("%s", value);
    }
    override string toString() {
        return value ? "true" : "false";
    }
}
