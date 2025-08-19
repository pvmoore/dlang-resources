module resources.models.gltf.meshopt.meshopt_filter;

/**
 * https://github.com/KhronosGroup/gltf/tree/main/extensions/2.0/Vendor/EXT_meshopt_compression#appendix-b-filters
 *
 * D conversion of code from:
 * https://github.com/zeux/meshoptimizer/blob/master/src/vertexfilter.cpp
 */

import resources.all;

private {
    import resources.models.gltf.meshopt.meshopt;
    import std.math : fabs, sqrt;
}

void applyDecodeFilter(Filter filter, void* buffer, size_t count, size_t stride) {
    final switch(filter) {
        case Filter.NONE: break;
        case Filter.OCTAHEDRAL: 
            throwIf(!stride.isOneOf(4,8), "stride must be 4 or 8");
            if(stride == 4) {
                decodeFilterOct(buffer.as!(byte*), count);
            } else {
                decodeFilterOct(buffer.as!(short*), count);
            }
            break;
        case Filter.QUATERNION: 
            throwIf(stride != 8, "stride must be 8");
            decodeFilterQuat(buffer.as!(short*), count); 
            break;
        case Filter.EXPONENTIAL: 
            throwIf(stride != 4, "stride must be 4");
            decodeFilterExp(buffer.as!(uint*), count); 
            break;
    }
}

void decodeFilterOct(T)(T* data, size_t count) {

	const float max = cast(float)((1 << (T.sizeof * 8 - 1)) - 1);

	for(size_t i = 0; i < count; ++i) {
		// convert x and y to floats and reconstruct z; this assumes zf encodes 1.f at the same bit count
		float x = cast(float)(data[i * 4 + 0]);
		float y = cast(float)(data[i * 4 + 1]);
		float z = cast(float)(data[i * 4 + 2]) - fabs(x) - fabs(y);

		// fixup octahedral coordinates for z<0
		float t = (z >= 0.0f) ? 0.0f : z;

		x += (x >= 0.0f) ? t : -t;
		y += (y >= 0.0f) ? t : -t;

		// compute normal length & scale
		float l = sqrt(x * x + y * y + z * z);
		float s = max / l;

		// rounded signed float->int
		int xf = cast(int)(x * s + (x >= 0.0f ? 0.5f : -0.5f));
		int yf = cast(int)(y * s + (y >= 0.0f ? 0.5f : -0.5f));
		int zf = cast(int)(z * s + (z >= 0.0f ? 0.5f : -0.5f));

		data[i * 4 + 0] = cast(T)(xf);
		data[i * 4 + 1] = cast(T)(yf);
		data[i * 4 + 2] = cast(T)(zf);
	}
}

void decodeFilterQuat(short* data, size_t count) {

    const float scale = 1.0f / sqrt(2.0f);

    for(size_t i = 0; i < count; ++i) {
        // recover scale from the high byte of the component
        int sf = data[i * 4 + 3] | 3;
        float ss = scale / cast(float)(sf);

        // convert x/y/z to [-1..1] (scaled...)
        float x = cast(float)(data[i * 4 + 0]) * ss;
        float y = cast(float)(data[i * 4 + 1]) * ss;
        float z = cast(float)(data[i * 4 + 2]) * ss;

        // reconstruct w as a square root; we clamp to 0.f to avoid NaN due to precision errors
        float ww = 1.0f - x * x - y * y - z * z;
        float w = sqrt(ww >= 0.0f ? ww : 0.0f);

        // rounded signed float->int
        int xf = cast(int)(x * 32767.0f + (x >= 0.0f ? 0.5f : -0.5f));
        int yf = cast(int)(y * 32767.0f + (y >= 0.0f ? 0.5f : -0.5f));
        int zf = cast(int)(z * 32767.0f + (z >= 0.0f ? 0.5f : -0.5f));
        int wf = cast(int)(w * 32767.0f + 0.5f);

        int qc = data[i * 4 + 3] & 3;

        // output order is dictated by input index
        data[i * 4 + ((qc + 1) & 3)] = cast(short)(xf);
        data[i * 4 + ((qc + 2) & 3)] = cast(short)(yf);
        data[i * 4 + ((qc + 3) & 3)] = cast(short)(zf);
        data[i * 4 + ((qc + 0) & 3)] = cast(short)(wf);
    }
}

void decodeFilterExp(uint* data, size_t count) {

    static union U {
        float f;
        uint ui;
    } 

	for(size_t i = 0; i < count; ++i) {
		uint v = data[i];

		// decode mantissa and exponent
		int m = cast(int)(v << 8) >> 8;
		int e = cast(int)(v) >> 24;

		// optimized version of ldexp(float(m), e)
        U u;
		u.ui = cast(uint)(e + 127) << 23;
		u.f  = u.f * cast(float)(m);

		data[i] = u.ui;
	}
}
 
