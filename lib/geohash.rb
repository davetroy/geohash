require 'geohash_native'
require 'geo_ruby'
require 'georuby-extras'
#require 'geo_ruby_extensions'

module GeoRuby
  module SimpleFeatures
    class GeoHash < Envelope
  
      extend GeoHashNative
      attr_reader :value, :point

      BASE32="0123456789bcdefghjkmnpqrstuvwxyz"
  
      # Create new geohash from a Point, String, or Array of Latlon
      def initialize(*params)
        if (params.first.is_a?(Point))
          point, precision = params
          @value = GeoHash.encode_base(point.x, point.y, precision || 10)
          @point = point
        elsif (params.first.is_a?(String))
          @value = params.first
        elsif (params.size>=2 && params[0].is_a?(Float) && params[1].is_a?(Float))
          precision = params[2] || 10
          @value = GeoHash.encode_base(params[0], params[1], precision)
          @point = Point.from_lon_lat(params[0], params[1])
        end
        points = GeoHash.decode_bbox(@value)
        @lower_corner, @upper_corner =  points.collect{|point_coords| Point.from_coordinates(point_coords,srid,with_z)}
        @point ||= center
      end

      # Return the geohash string value when representing as string
      def to_s
        @value
      end
    
      # Does a given geohash envelope contain the specified point?
      def contains?(point)
        ((@lower_corner.x..@upper_corner.x) === point.x) &&
        ((@lower_corner.y..@upper_corner.y) === point.y)
      end

      # Compute a neighbor for a given geohash of the same length
      # Directions are constants (0,1,2,3 = right, left, top, bottom)
      def neighbor(dir)
        GeoHash.new(GeoHash.calculate_adjacent(@value, dir))
      end
  
      # Returns the immediate neighbors of a given hash value,
      # to the same level of precision as the source
      def neighbors(options = {})
        return @neighbors if @neighbors
        right_left = [0,1].map { |d| GeoHash.calculate_adjacent(@value, d) }
        top_bottom = [2,3].map { |d| GeoHash.calculate_adjacent(@value, d) }
        diagonals = right_left.map { |v| [2,3].map { |d| GeoHash.calculate_adjacent(v, d) } }.flatten
        @neighbors = right_left + top_bottom + diagonals
        options[:value_only] ? @neighbors : @neighbors.map { |v| GeoHash.new(v) }
      end
      
      # Keep extending a given geohash in a given direction until we reach a (known) destination geohash
      # Return a list of the hashes, including the start and destination hashes
      def extend_to(destination_hash, dir)
        list = [self]
        current = self
        begin
          new_neighbor = GeoHash.new(GeoHash.calculate_adjacent(current.value, dir))
          list << new_neighbor
          current = new_neighbor
        end until current.value == destination_hash.value
        list
      end
      
      # List of same-resolution neighbor geohashes within a specified radius
      def neighbors_in_range_old(radius)
        cells = [45,135,225,315].map { |b| GeoHash.new(Point.from_point(self.point,b,radius), value.size) }
        cells << self
        top_row = cells[3].extend_to(cells[0], 0)
        rows = top_row
        current_row = top_row
        begin
          row = current_row.map { |c| GeoHash.new(GeoHash.calculate_adjacent(c.value, 3)) }
          rows.concat(row)
          current_row = row
        end until current_row.first.value == cells[2].value
        rows.concat [265,270,90,95,85,80,100].map { |b| GeoHash.new(self.point.point_at_bearing_and_distance(b,radius), value.size) }
      end
      
      
      def neighbors_in_range(radius, from_point, list=[])
        if hash_within_radius?(self, radius, from_point)
          list << self
          [0,1,2,3].map { |d| neighbor(d).neighbors_in_range(radius, from_point, list) }.flatten
        end
        p list
        list
      end
  
      # All four corners of a geohash envelope
      def four_corners
        upper_corner_2 = Point.from_lon_lat(@lower_corner.lon, @upper_corner.lat)
        lower_corner_2 = Point.from_lon_lat(@upper_corner.lon, @lower_corner.lat)
        [@upper_corner, upper_corner_2, @lower_corner, lower_corner_2]
      end
  
      # All thirty-two child geohashes of a geohash envelope
      def children
        BASE32.scan(/./).map { |digit| GeoHash.new("#{self.value}#{digit}") }
      end

      # All children of a geohash envelope within a radius from the given point;
      # Keeps going recursively until the given maximum_resolution geohash
      def children_within_radius(r, from_point=self.center, maximum_resolution=6)
        return [self] if hash_within_radius?(self, r, from_point)
        list = []
        children.each do |child|
          if hash_within_radius?(child, r, from_point)
            list << child
          elsif @value.size < maximum_resolution
            list.concat child.children_within_radius(r, from_point)
          end
        end
        list
      end
  
      # Find the largest parent geohash that is still within the given radius from the center
      def largest_parent_within_radius(r)
        last_parent = nil
        (@value.size-1).downto(3) do |precision|
          last_parent = GeoHash.new(self.point,precision)
          break if radius_within_hash?(last_parent, r)
        end
        last_parent
      end
      
      # Determine if a hash is contained within a radius from the specified point
      def hash_within_radius?(gh, r, from_point=self.point)
        return false if gh.four_corners.find { |p| from_point.ellipsoidal_distance(p) > r }
        true
      end
      
      # Determine if a hash is contained within a radius from the specified point
      def radius_within_hash?(gh, r, from_point=self.point)
        return false if gh.four_corners.find { |p| from_point.ellipsoidal_distance(p) <= r }
        true
      end
            
      # Gives a list of all neighbor goehashes within a radius, up to the maximum resolution
      def neighbors_within_radius(r, maximum_resolution=6)
        #.neighbors_in_range(r, self.point)
        #.map { |parent| parent }.flatten
        largest_parent_within_radius(r).children_within_radius(r, self.point, maximum_resolution)
      end
      
    end
  end
end
