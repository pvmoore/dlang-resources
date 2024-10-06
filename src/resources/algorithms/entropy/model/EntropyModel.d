module resources.algorithms.entropy.model.EntropyModel;

import resources.all;

public import resources.algorithms.entropy.model.Order0StaticModel;
public import resources.algorithms.entropy.model.Order0DynamicModel;

struct MSymbol {
	ulong low;
	ulong high;
    int value;
}

interface EntropyModel {
    MSymbol getSymbolFromValue(int value);
    MSymbol getSymbolFromRange(ulong range);
    ulong   getScale();
}
