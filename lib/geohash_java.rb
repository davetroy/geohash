require 'java'
require File.expand_path('../geohash-java.jar', __FILE__)

class GeoHash
  class <<self
    JavaGeoHash = Java::ChHsrGeohash::GeoHash

    def encode_base(lat, lon, precision)
      JavaGeoHash.with_character_precision(lat, lon, precision).to_base32
    end

    def decode_base(geohash)
      point = JavaGeoHash.from_geohash_string(geohash.downcase).point
      [point.latitude, point.longitude]
    end

    def decode_bbox(geohash)
      bounding_box = JavaGeoHash.from_geohash_string(geohash.downcase).bounding_box
      [[bounding_box.min_lat, bounding_box.min_lon], [bounding_box.max_lat, bounding_box.max_lon]]
    end

    def calculate_adjacent(geohash, dir)
      java_geo_hash = JavaGeoHash.from_geohash_string(geohash.downcase)
      neighbor_geo_hash =
        case dir
        when 0 then java_geo_hash.get_eastern_neighbour
        when 1 then java_geo_hash.get_western_neighbour
        when 2 then java_geo_hash.get_northern_neighbour
        when 3 then java_geo_hash.get_southern_neighbour
        end
      neighbor_geo_hash.to_base32
    end
  end
end
