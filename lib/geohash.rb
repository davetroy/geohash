require 'geohash_native'
require 'geo_ruby'

class Float
  def decimals(places)
    n = (self * (10 ** places)).round
    n.to_f/(10**places)
  end
end

class GeoHash < GeoRuby::SimpleFeatures::Envelope
  
  extend GeoHashCalculations
  attr_reader :value
  
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
  
  def self.hashes_within_radius(point, precision=10)
    GeoHash.new(point, precision)
  end
  
  # # Create a new GeoHash object from a geohash or from a latlon
  # def initialize(*params)
  #   if params.first.is_a?(Float)
  #     @value = GeoHash.encode(*params)
  #   elsif params.first.is_a?(GeoRuby::SimpleFeatures::Point)
  #     @value = GeoHash.encode(params.first.y, params.first.x, params[1])
  #   else
  #     @value = params.first
  #   end
  # end
  
  def self.from_point(point, precision=10)
    p point
    @value = GeoHash.encode_base(point.y, point.x, precision)
    from_coordinates(GeoHash.decode_bbox(@value))
    self
  end

  def to_s
    @value
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
  
  def search_within_radius(r)
    puts "upper corner of #{@value} is within #{r}km of center" if center.ellipsoidal_distance(upper_corner) < r
    puts "lower corner of #{@value} is within #{r}km of center" if center.ellipsoidal_distance(lower_corner) < r
  end
  
  def search_within_box_around
  end
  
end
