module resources.algorithms.transforms.DeltaEncoder;

import resources.all;

final class DeltaEncoder(T) {
public:
    T[] encode(T[] input) {
        T[] output = new T[input.length];

        T last = 0;
        foreach(i, value; input) {
            output[i] = (value - last).as!T;
            last = value;
        }

        return output;
    }
    T[] decode(T[] input) {
        T[] output = new T[input.length];

        T last = 0;
        foreach(i, value; input) {
            output[i] = (value + last).as!T;
            last = output[i];
        }

        return output;
    }
private:
}
