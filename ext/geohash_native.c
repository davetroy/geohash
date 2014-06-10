// geohash-native.c
// (c) 2008-2010 David Troy
// davetroy@gmail.com
// 
// (The MIT License)
// 
// Copyright (c) 2008 David Troy, Roundhouse Technologies LLC
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// 'Software'), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include "ruby.h"
#include <ctype.h>

static VALUE rb_cGeoHash;

#define BASE32	"0123456789bcdefghjkmnpqrstuvwxyz"

static void decode_geohash_bbox(char *geohash, double *lat, double *lon) {
	int i, j, hashlen;
	double lat_err, lon_err;
	char c, cd, mask, is_even=1;
	static char bits[] = {16,8,4,2,1};
	
	lat[0] = -90.0;  lat[1] = 90.0;
	lon[0] = -180.0; lon[1] = 180.0;
	lat_err = 90.0;  lon_err = 180.0;
	hashlen = strlen(geohash);
	
	for (i=0; i<hashlen; i++) {
		c = tolower(geohash[i]);
		cd = strchr(BASE32, c)-BASE32;
		for (j=0; j<5; j++) {
			mask = bits[j];
			if (is_even) {
				lon_err /= 2;
				lon[!(cd&mask)] = (lon[0] + lon[1])/2;
			} else {
				lat_err /= 2;
				lat[!(cd&mask)] = (lat[0] + lat[1])/2;
			}
			is_even = !is_even;
		}
	}
}

static void decode_geohash(char *geohash, double *point) {
	double lat[2], lon[2];

	decode_geohash_bbox(geohash, lat, lon);

	point[0] = (lat[0] + lat[1]) / 2;
	point[1] = (lon[0] + lon[1]) / 2;
}

static void encode_geohash(double latitude, double longitude, int precision, char *geohash) {
	int is_even=1, i=0;
	double lat[2], lon[2], mid;
	char bits[] = {16,8,4,2,1};
	int bit=0, ch=0;

	lat[0] = -90.0;  lat[1] = 90.0;
	lon[0] = -180.0; lon[1] = 180.0;
	
	while (i < precision) {
		if (is_even) {
			mid = (lon[0] + lon[1]) / 2;
			if (longitude > mid) {
				ch |= bits[bit];
				lon[0] = mid;
			} else
				lon[1] = mid;
		} else {
			mid = (lat[0] + lat[1]) / 2;
			if (latitude > mid) {
				ch |= bits[bit];
				lat[0] = mid;
			} else
				lat[1] = mid;
		}
		
		is_even = !is_even;
		if (bit < 4)
			bit++;
		else {
			geohash[i++] = BASE32[ch];
			bit = 0;
			ch = 0;
		}
	}
	geohash[i] = 0;
}

static VALUE encode(VALUE self, VALUE lat, VALUE lon, VALUE precision)
{
	VALUE geohash;
	char str[15];
	int digits=10;
	
	digits = NUM2INT(precision);
	
	Check_Type(lat, T_FLOAT);
	Check_Type(lon, T_FLOAT);
	if (digits <3 || digits > 12)
		digits = 12;

	encode_geohash(RFLOAT_VALUE(lat), RFLOAT_VALUE(lon), digits, str);

	geohash = rb_str_new2(str);
	return geohash;
}

static VALUE decode_bbox(VALUE self, VALUE str)
{
	VALUE ary, ret;
	double lat[2], lon[2];
	Check_Type(str, T_STRING);

	decode_geohash_bbox(RSTRING_PTR(str), lat, lon);

	ret = rb_ary_new2(2); /* [[lat[0], lon[0]], [lat[1], lon[1]]] */

	ary = rb_ary_new2(2); /* [lat[0], lon[0]] */
	rb_ary_store(ary, 0, rb_float_new(lat[0]));
	rb_ary_store(ary, 1, rb_float_new(lon[0]));
	rb_ary_store(ret, 0, ary);

	ary = rb_ary_new2(2); /* [lat[1], lon[1]] */
	rb_ary_store(ary, 0, rb_float_new(lat[1]));
	rb_ary_store(ary, 1, rb_float_new(lon[1]));
	rb_ary_store(ret, 1, ary);

	return ret;
}

static VALUE decode(VALUE self, VALUE str)
{
	VALUE ary;
	double point[2];
	Check_Type(str, T_STRING);
	
	decode_geohash(RSTRING_PTR(str), point);
	
	ary = rb_ary_new2(2);
	rb_ary_store(ary, 0, rb_float_new(point[0]));
	rb_ary_store(ary, 1, rb_float_new(point[1]));
	return ary;
}

// Given a particular geohash string, a direction, and a final length
// Compute a neighbor using base32 lookups, recursively when necessary
void get_neighbor(char *str, int dir, int hashlen)
{
	/* Right, Left, Top, Bottom */

	static char *neighbors[] = { "bc01fg45238967deuvhjyznpkmstqrwx",
														 	 "238967debc01fg45kmstqrwxuvhjyznp",
														 	 "p0r21436x8zb9dcf5h7kjnmqesgutwvy",
														   "14365h7k9dcfesgujnmqp0r2twvyx8zb" };
												
	static char *borders[] = { "bcfguvyz", "0145hjnp", "prxz", "028b" };

	char last_chr, *border, *neighbor;
	int index = ( 2 * (hashlen % 2) + dir) % 4;
	neighbor = neighbors[index];
	border = borders[index];
	last_chr = str[hashlen-1];
	if (strchr(border,last_chr))
		get_neighbor(str, dir, hashlen-1);
	str[hashlen-1] = BASE32[strchr(neighbor, last_chr)-neighbor];
}

// Acts as Ruby API wrapper to get_neighbor function, which is recursive and does nasty C things
static VALUE calculate_adjacent(VALUE self, VALUE geohash, VALUE dir)
{
	char *str;
	VALUE ret_val;
	Check_Type(geohash, T_STRING);
	Check_Type(dir, T_FIXNUM);
	str = RSTRING_PTR(geohash);
	if (!strlen(str)) return Qnil;
	ret_val = rb_str_new(str,strlen(str));
	get_neighbor(RSTRING_PTR(ret_val), NUM2INT(dir), strlen(str));
	return ret_val;
}

void Init_geohash_native()
{
	rb_cGeoHash = rb_define_class("GeoHash", rb_cObject);
	rb_define_singleton_method(rb_cGeoHash, "decode_bbox", decode_bbox, 1);
	rb_define_singleton_method(rb_cGeoHash, "decode_base", decode, 1);
	rb_define_singleton_method(rb_cGeoHash, "encode_base", encode, 3);
	rb_define_singleton_method(rb_cGeoHash, "calculate_adjacent", calculate_adjacent, 2);
}

// end
