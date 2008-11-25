require 'geohash_native'

class Float
  def decimals(places)
    n = (self * (10 ** places)).round
    n.to_f/(10**places)
  end
end

class GeoHash
  
  VERSION = '1.1.0'

  # BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"

  # @@neighbors = {:right  => { :even => "bc01fg45238967deuvhjyznpkmstqrwx" },
  #                :left   => { :even => "238967debc01fg45kmstqrwxuvhjyznp" },
  #                :top    => { :even => "p0r21436x8zb9dcf5h7kjnmqesgutwvy" },
  #                :bottom => { :even => "14365h7k9dcfesgujnmqp0r2twvyx8zb" } }
  # 
  # @@borders   = {:right  => { :even => "bcfguvyz" },
  #                :left   => { :even => "0145hjnp" },
  #                :top    => { :even => "prxz" },
  #                :bottom => { :even => "028b" } }
  #               
  # @@neighbors[:bottom][:odd] = @@neighbors[:left][:even]
  # @@neighbors[:top][:odd] = @@neighbors[:right][:even]
  # @@neighbors[:left][:odd] = @@neighbors[:bottom][:even]
  # @@neighbors[:right][:odd] = @@neighbors[:top][:even]
  # 
  # @@borders[:bottom][:odd] = @@borders[:left][:even]
  # @@borders[:top][:odd] = @@borders[:right][:even]
  # @@borders[:left][:odd] = @@borders[:bottom][:even]
  # @@borders[:right][:odd] = @@borders[:top][:even]
  # 
  # NEIGHBOR_DIRECTIONS = [ [:top, :bottom], [:left, :right] ]
  
  # Encode latitude and longitude to a geohash with precision digits
  def self.encode(lat, lon, precision=10)
    encode_base(lat, lon, precision)
  end

  # Decode a geohash to a latitude and longitude with decimals digits
  def self.decode(geohash, decimals=5)
    lat, lon = decode_base(geohash)
    [lat.decimals(decimals), lon.decimals(decimals)]
  end
  
  # def self.calculate_adjacent(geohash, dir)
  #   geohash.downcase!
  #   last_chr = geohash[-1]
  #   type = (geohash.size % 2).zero? ? :even : :odd
  #   base = geohash.chop
  #   if (@@borders[dir][type].index(last_chr))
  #     base = calculate_adjacent(base, dir)
  #   end
  #   base.concat(BASE32[@@neighbors[dir][type].index(last_chr)])
  # end
  
  def initialize(*params)
    if params.first.is_a?(Float)
      @value = GeoHash.encode(*params)
      @latitude, @longitude = params
    else
      @value = params.first
      @latitude, @longitude = GeoHash.decode(@value)
    end
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
