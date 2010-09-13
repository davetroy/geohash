begin
  require 'geohash_native'
rescue LoadError => e
  require File.expand_path('../geohash_java', __FILE__)
end

class Float
  def decimals(places)
    n = (self * (10 ** places)).round
    n.to_f/(10**places)
  end
end

class GeoHash
  
  VERSION = '1.1.0'

  NEIGHBOR_DIRECTIONS = [ [0, 1], [2, 3] ]
  
  # Encode latitude and longitude to a geohash with precision digits
  def self.encode(lat, lon, precision=10)
    encode_base(lat, lon, precision)
  end

  # Decode a geohash to a latitude and longitude with decimals digits
  def self.decode(geohash, decimals=5)
    lat, lon = decode_base(geohash)
    [lat.decimals(decimals), lon.decimals(decimals)]
  end
  
  # Create a new GeoHash object from a geohash or from a latlon
  def initialize(*params)
    if params.first.is_a?(Float)
      @value = GeoHash.encode(*params)
      @latitude, @longitude = params
    else
      @value = params.first
      @latitude, @longitude = GeoHash.decode(@value)
    end
    @bounding_box = GeoHash.decode_bbox(@value)
  end
  
  def to_s
    @value
  end
  
  def to_bbox
    GeoHash.decode_bbox(@value)
  end
  
  def neighbor(dir)
    GeoHash.calculate_adjacent(@value, dir)
  end
  
  def neighbors
    immediate = NEIGHBOR_DIRECTIONS.flatten.map do |d|
      neighbor(d)
    end
    diagonals = NEIGHBOR_DIRECTIONS.first.map do |y|
      NEIGHBOR_DIRECTIONS.last.map do |x|
        GeoHash.calculate_adjacent(GeoHash.calculate_adjacent(@value, x), y)
      end
    end.flatten
    immediate + diagonals
  end
end
