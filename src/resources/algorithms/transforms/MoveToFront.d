module resources.algorithms.transforms.MoveToFront;

import resources.all;

final class MoveToFront(T) {
public:
    T[] encode(T[] input, T minValue, T maxValue) {
        T[] list   = initialiseList(minValue, maxValue);
        T[] output = new T[input.length];

        foreach(i, value; input) {
            uint index = findIndex(list, value);
            output[i] = index.as!T;

            moveToFront(list, index);
        }

        return output;
    }
    T[] decode(T[] input, T minValue, T maxValue) {
        T[] list   = initialiseList(minValue, maxValue);
        T[] output = new T[input.length];

        foreach(i, index; input) {
            output[i] = list[index];
            moveToFront(list, index);
        }

        return output;
    }
private:
    T[] initialiseList(T minValue, T maxValue) {
        T[] list = new T[(maxValue-minValue) + 1];
        foreach(i; 0..list.length) {
            list[i] = (minValue + i).as!T;
        }
        return list;
    }
    uint findIndex(T[] list, T value) {
        foreach(i; 0..list.length) {
            if(list[i] == value) return i.as!uint;
        }
        assert(false);
    }
    void moveToFront(T[] list, uint index) {
        // index is already at the front
        if(index == 0) return;

        T value = list[index];
        for(uint i = index; i > 0; i--) {
            list[i] = list[i-1];
        }
        list[0] = value;
    }
}
