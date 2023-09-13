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
    final bool isObject() { return kind == Kind.OBJECT; }
    final bool isArray() { return kind == Kind.ARRAY; }
    final bool isNull() { return kind == Kind.NULL; }
    final bool isString() { return kind == Kind.STRING; }
    final bool isNumber() { return kind == Kind.NUMBER; }
    final bool isBoolean() { return kind == Kind.BOOLEAN; }

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
    // Only makes sense for J5Object
    bool hasKey(string key) {
        if(isObject()) return this.as!J5Object.hasKey(key);
        return false;
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
    this() {
        this.kind = Kind.OBJECT;
    }
    this(J5Value[string] map) {
        this();   
        this.map = map;
    }

    J5Object add(string key, J5Value value) {
        map[key] = value;
        return this;
    }

    override bool isEmpty() { return map.length ==0; }
    override bool hasKey(string key) { return (key in map) !is null; }

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
private:
    J5Value[string] map;    
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Array : J5Value {
public: 
    this() {
        this.kind = Kind.ARRAY;
    }
    this(J5Value[] array) {
        this();
        this.array = array;
    }

    J5Array add(J5Value value) {
        array ~= value;
        return this;
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
private:
    J5Value[] array;    
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Number : J5Value {
public:
    string value;

    this(string value) {
        this.kind = Kind.NUMBER;
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
        this.kind = Kind.STRING;
        this.value = value[1..$-1];
        this.quote = value[0];
    }

    alias opEquals = J5Value.opEquals;
    override bool opEquals(string other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5String && other.as!J5String.value == value;
    }
    override string toString() {
        return value;
    }
private:
    char quote;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Boolean : J5Value {
public:
    bool value;

    this(bool value) {
        this.kind = Kind.BOOLEAN;
        this.value = value;
    }

    alias opEquals = J5Value.opEquals;
    override bool opEquals(bool other) {
        return value == other;
    }
    override bool opEquals(Object other) {
        return other.isA!J5Boolean && other.as!J5Boolean.value == value;
    }
    override string toString() {
        return value ? "true" : "false";
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Null : J5Value {
public:
    this() {
        this.kind = Kind.NULL;
    }
    alias opEquals = J5Value.opEquals;
    override bool opEquals(Object other) {
        return other.isA!J5Null;
    }
    override string toString() {
        return "null";
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class J5Serialiser {
public:
    this(bool pretty) {
        this.buf = new StringBuffer();
        this.stack = new Stack!string;
        this.pretty = pretty;
    }
    string stringify(J5Value v) {
        buf.clear();
        stack.clear();
        process(v);
        return buf.toString();
    }
private:
    StringBuffer buf;
    Stack!string stack;
    bool pretty;
    string prefix;

    void push() {
        stack.push(prefix);
        prefix = prefix ~ "  ";
    }
    void pop() {
        prefix = stack.pop();
    }
    void process(J5Value v) {
        final switch(v.kind) with(Kind) {
            case OBJECT: process(v.as!J5Object); break;
            case ARRAY: process(v.as!J5Array); break;
            case STRING: process(v.as!J5String); break;
            case NUMBER: process(v.as!J5Number); break;
            case BOOLEAN: process(v.as!J5Boolean); break;
            case NULL: process(v.as!J5Null); break;
        }
    }
    void process(J5Object obj) {
        buf.add("{");
        int i = 0;
        if(pretty) {
            push();
            foreach(e; obj.map.byKeyValue()) {
                if(i++>0) buf.add(",");
                buf.add("\n").add(prefix);
                buf.add("\"").add(e.key).add("\" : ");
                process(e.value);
            }
            pop();
            if(!obj.isEmpty()) buf.add("\n").add(prefix);
        } else {
            foreach(e; obj.map.byKeyValue()) {
                if(i++>0) buf.add(",");
                buf.add("\"").add(e.key).add("\":");
                process(e.value);
            }    
        }
        buf.add("}");
    }
    void process(J5Array obj) {
        buf.add("[");
        if(pretty) {
            push();
            foreach(i, v; obj.array) {
                if(i>0) buf.add(",");
                buf.add("\n").add(prefix);
                process(v);
            }
            pop();
            if(!obj.isEmpty()) buf.add("\n").add(prefix);
        } else {
            foreach(i, v; obj.array) {
                if(i>0) buf.add(",");
                process(v);
            }
        }
        buf.add("]");       
    }
    void process(J5String obj) {
        buf.add(obj.quote).add(obj.value).add(obj.quote);
    }
    void process(J5Number obj) {
        buf.add(obj.value);
    }
    void process(J5Boolean obj) {
        buf.add(obj.value ? "true" : "false");
    }
    void process(J5Null obj) {
        buf.add("null");
    }
}