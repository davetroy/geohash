require 'geohash_native'
require 'geo_ruby'

module GeoRuby
  module SimpleFeatures
    class GeoHash < Envelope
  
      extend GeoHashNative
      attr_reader :value

      BASE32="0123456789bcdefghjkmnpqrstuvwxyz"
  
      # Create new geohash from a Point, String, or Array of Latlon
      def initialize(*params)
        if (params.first.is_a?(Point))
          point, precision = params
          @value = GeoHash.encode_base(point.y, point.x, precision || 10)
        elsif (params.first.is_a?(String))
          @value = params.first
        elsif (params.size>=2 && params[0].is_a?(Float) && params[1].is_a?(Float))
          precision = params[2] || 10
          @value = GeoHash.encode_base(params[1], params[0], precision)
        end
        points = GeoHash.decode_bbox(@value)
        @lower_corner, @upper_corner =  points.collect{|point_coords| Point.from_coordinates(point_coords,srid,with_z)}
      end
  
      def to_s
        @value
      end
    
      def contains?(point)
        ((@lower_corner.x..@upper_corner.x) === point.x) &&
        ((@lower_corner.y..@upper_corner.y) === point.y)
      end

      def neighbor(dir)
        GeoHash.new(GeoHash.calculate_adjacent(@value, dir))
      end
  
      def neighbors
        return @neighbors if @neighbors
        right_left = [0,1].map { |d| neighbor(d) }
        top_bottom = [2,3].map { |d| neighbor(d) }
        diagonals = right_left.map { |n| [2,3].map { |d| n.neighbor(d) } }.flatten
        @neighbors = right_left + top_bottom + diagonals
      end
  
      def four_corners
        upper_corner_2 = Point.from_lon_lat(@lower_corner.lon, @upper_corner.lat)
        lower_corner_2 = Point.from_lon_lat(@upper_corner.lon, @lower_corner.lat)
        [@upper_corner, upper_corner_2, @lower_corner, lower_corner_2]
      end
  
      def children
        BASE32.scan(/./).map { |digit| GeoHash.new("#{self.value}#{digit}") }
      end

      def children_within_radius(r, from_point=self.center)
        return [] if self.value.size==8
        list = []
        children.each do |child|
          if hash_within_radius?(child, r, from_point)
            list << child
          else
            list.concat(child.children_within_radius(r, from_point))
          end
        end
        list
      end
  
      def largest_parent_within_radius(r)
        parents = (1..@value.size-1).to_a.map { |l| @value[0..l] }
        last_parent = nil
        parents.find { |p| last_parent = GeoHash.new(p); hash_within_radius?(last_parent, r) }
        last_parent
      end
      
      def hash_within_radius?(gh, r, from_point=self.center)
        included_corners = gh.four_corners.find_all { |p| from_point.ellipsoidal_distance(p) <= r }
        included_corners.size == 4
      end
      
      def extend_in_direction(dir, r)
        neighbor_list = []
        current = self
        begin
          new_neighbor = GeoHash.new(GeoHash.calculate_adjacent(current.value, dir))
          valid = hash_within_radius?(new_neighbor,r)
          neighbor_list << new_neighbor if valid
          current = new_neighbor
        end until (!valid)
        neighbor_list
      end
      
      def extend_n_times(n,dir)
        neighbor_list = []
        current = self
        1.upto(n) do
          new_neighbor = GeoHash.new(GeoHash.calculate_adjacent(current.value, dir))
          neighbor_list << new_neighbor
          current = new_neighbor
        end
        neighbor_list
      end
      
      def neighbors_within_radius(r)
        right_neighbors = extend_in_direction(0, r)
        left_neighbors = extend_in_direction(1, r)
        top_neighbors = extend_in_direction(2, r)
        bottom_neighbors = extend_in_direction(3, r)
        upper_right_neighbors = right_neighbors.map { |n| n.extend_n_times(top_neighbors.size-1, 2) }.flatten
        lower_right_neighbors = right_neighbors.map { |n| n.extend_n_times(top_neighbors.size-1, 3) }.flatten
        upper_left_neighbors = left_neighbors.map { |n| n.extend_n_times(bottom_neighbors.size-1, 2) }.flatten
        lower_left_neighbors = left_neighbors.map { |n| n.extend_n_times(bottom_neighbors.size-1, 3) }.flatten
        all = (right_neighbors + left_neighbors + top_neighbors + bottom_neighbors)  << self
        all += (upper_right_neighbors + lower_right_neighbors + upper_left_neighbors + lower_left_neighbors)
        all.delete_if { |n| !hash_within_radius?(n, r) }
        
        largest_parent = largest_parent_within_radius(r)
        largest_right_neighbors = largest_parent.extend_in_direction(0, r)
        largest_left_neighbors = largest_parent.extend_in_direction(1, r)
        largest_top_neighbors = largest_parent.extend_in_direction(2, r)
        largest_bottom_neighbors = largest_parent.extend_in_direction(3, r)
        largest_upper_right_neighbors = largest_right_neighbors.map { |n| n.extend_n_times(largest_top_neighbors.size-1, 2) }.flatten
        largest_lower_right_neighbors = largest_right_neighbors.map { |n| n.extend_n_times(largest_top_neighbors.size-1, 3) }.flatten
        largest_upper_left_neighbors = largest_left_neighbors.map { |n| n.extend_n_times(largest_bottom_neighbors.size-1, 2) }.flatten
        largest_lower_left_neighbors = largest_left_neighbors.map { |n| n.extend_n_times(largest_bottom_neighbors.size-1, 3) }.flatten
        largest_all = (largest_right_neighbors + largest_left_neighbors + largest_top_neighbors + largest_bottom_neighbors)  << largest_parent
        largest_all += (largest_upper_right_neighbors + largest_lower_right_neighbors + largest_upper_left_neighbors + largest_lower_left_neighbors)
        all = all.delete_if { |n| largest_all.find { |l| n.value.starts_with?(l.value) } }
        largest_all.concat(all)
      end
      
      def neighbors_within_radius2(r)
        largest_parent = largest_parent_within_radius(r)
        largest_right_neighbors = largest_parent.extend_in_direction(0, r)
        largest_left_neighbors = largest_parent.extend_in_direction(1, r)
        largest_top_neighbors = largest_parent.extend_in_direction(2, r)
        largest_bottom_neighbors = largest_parent.extend_in_direction(3, r)
        largest_upper_right_neighbors = largest_right_neighbors.map { |n| n.extend_n_times(largest_top_neighbors.size-1, 2) }.flatten
        largest_lower_right_neighbors = largest_right_neighbors.map { |n| n.extend_n_times(largest_top_neighbors.size-1, 3) }.flatten
        largest_upper_left_neighbors = largest_left_neighbors.map { |n| n.extend_n_times(largest_bottom_neighbors.size-1, 2) }.flatten
        largest_lower_left_neighbors = largest_left_neighbors.map { |n| n.extend_n_times(largest_bottom_neighbors.size-1, 3) }.flatten
        largest_all = (largest_right_neighbors + largest_left_neighbors + largest_top_neighbors + largest_bottom_neighbors)  << largest_parent
        largest_all += (largest_upper_right_neighbors + largest_lower_right_neighbors + largest_upper_left_neighbors + largest_lower_left_neighbors)
        all_children = []
        largest_all.each do |parent|
          if !hash_within_radius?(parent, r)
            all_children.concat(parent.children_within_radius(r, self.center))
            largest_all.delete(parent)
          end
        end
        largest_all.concat(all_children)
      end
      
    end
  end
end
