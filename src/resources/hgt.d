module resources.hgt;
/**
 *  Shuttle Radar Topography Mission (SRTM) Data file.
 *
 *  Filename format is expected to be:
 *      [N|S]latitude[E|W]longitude
 *      eg. N33W006.hgt
 *
 *  Each file contains either 1 or 3 inch data of 1 degree square.
 *
 *  Possible formats:
 *  1 inch:
 *      Each file consists of 3601*3601 cells
 *      Each cell is ushort (big-endian)
 *  3 inch:
 *      Each file consists of 1201*1201 cells
 *      Each cell is ushort (big-endian)
 *
 *  http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
 *  http://www.viewfinderpanoramas.org/dem3.html#hgt
 *  http://vterrain.org/Elevation/Artificial/
 */
import resources.all;

final class HGT {
    private static const ONE_INCH_SIZE   = 3601*3601*2;
    private static const THREE_INCH_SIZE = 1201*1201*2;
    ushort[] data;
    int latitude;   // -90 to +90 where 0 is on the equator
    int longitude;
    int inches;
    int width;
    int height;
    int maxHeight;

    ushort opIndex(uint x, uint y) {
        return data[x+y*width];
    }

    static HGT read(string filename) {
        auto hgt = new HGT;
        chat("Reading HGT file '%s'", filename);
        decodeLatLong(baseName(filename), hgt.latitude, hgt.longitude);
        chat("Lat=%s lon=%s", hgt.latitude, hgt.longitude);
        scope f = File(filename, "rb");
        if(f.size==ONE_INCH_SIZE) {
            hgt.inches = 3;
            hgt.width  = 3601;
            hgt.height = 3601;
            hgt.data   = new ushort[ONE_INCH_SIZE/2];
        } else if(f.size==THREE_INCH_SIZE) {
            hgt.inches = 1;
            hgt.width  = 1201;
            hgt.height = 1201;
            hgt.data   = new ushort[THREE_INCH_SIZE/2];
        } else {
            throw new Error("Unexpected HGT file size");
        }
        chat("Height data is %s inches", hgt.inches);

        f.rawRead(hgt.data);

        // convert to little-endian
        for(auto i=0; i<hgt.data.length; i++) {
            uint a = hgt.data[i];
            hgt.data[i] = cast(ushort)(a>>8) | ((a&0xff)<<8);
            if(a>hgt.maxHeight) hgt.maxHeight = a;
        }

        chat("%s", hgt.data[0]);
        chat("max=%s", hgt.maxHeight);
        return hgt;
    }
private:
    static void decodeLatLong(string filename, ref int lat, ref int lon) {
        auto m = filename.matchFirst(r"([N|S])(\d+)([E|W])(\d+)");
        auto ns = m[1];
        lat = m[2].to!int;
        auto ew = m[3];
        lon = m[4].to!int;
        if(ns=="S") lat = -lat;
        if(ew=="W") lon = -lon;
    }
}

