#!/usr/bin/env ruby
require "#{File.dirname(__FILE__)}/../ext/geohash_native"
require 'test/unit'
require 'test_helper'

class GeoHashNativeTest < Test::Unit::TestCase
  
  include GeoHashNative

  def test_decoding
    assert_coords_equal [39.0247389581054, -76.5110040642321], decode_base("dqcw4bnrs6s7")
    assert_coords_equal [37.791562, -122.398541], decode_base("9q8yyz8pg3bb")
    assert_coords_equal [37.791562, -122.398541], decode_base("9Q8YYZ8PG3BB")
    assert_coords_equal [42.60498046875, -5.60302734375], decode_base("ezs42")
    assert_coords_equal [-25.382708, -49.26550609], decode_base("6gkzwgjzn820")
    assert_coords_equal [-25.3826236, -49.265613555], decode_base("6gkzwgjz")
    assert_coords_equal [37.8564880, -122.255414], decode_base("9q9p658642g7")
  end

  def test_encoding
    assert_equal "dqcw4bnrs6s7", encode_base(-76.5110040642321, 39.0247389581054, 12)
    assert_equal "dqcw4bnrs6", encode_base(-76.5110040642321, 39.0247389581054 , 10)
    assert_equal "6gkzmg1u", encode_base(-49.315, -25.427,  8)
    assert_equal "ezs42", encode_base(-5.60302734375, 42.60498046875, 5)
  end

  def check_decoding(gh)
    exact = decode_base(gh)
    bbox = decode_bbox(gh)

    # check that the bbox is centered on the decoded point
    bbox_center = [(bbox[0][1] + bbox[1][1]) / 2, (bbox[0][0] + bbox[1][0]) / 2]
    assert_equal exact, bbox_center

    # check that the bounding box is the expected size
    bits = gh.size * 5
    lon_bits = (bits.to_f/2).ceil
    lat_bits = (bits.to_f/2).floor
    correct_size = [180.0/2**lat_bits, 360.0/2**lon_bits]
    bbox_size = [bbox[1][1] - bbox[0][1], bbox[1][0] - bbox[0][0]]
    assert_equal bbox_size, correct_size
  end  

  def test_decoding_bbox
    s = "dqcw4bnrs6s7"
    (s.length).downto(0) do |l|
      check_decoding(s[0..l])
    end
  end
  
  def test_neighbor_calculations
    assert_equal "dqcw5", calculate_adjacent("dqcw4", 0)  # right
    assert_equal "dqcw1", calculate_adjacent("dqcw4", 1)  # left
    
    assert_equal "dqctc", calculate_adjacent("dqcw1", 3)  # bottom

    assert_equal "dqcwh", calculate_adjacent("dqcw5", 0)  # right
    assert_equal "dqcw4", calculate_adjacent("dqcw5", 1)  # left
    assert_equal "dqcw7", calculate_adjacent("dqcw5", 2)  # top
    assert_equal "dqctg", calculate_adjacent("dqcw5", 3)  # bottom
  end
  
  # require 'benchmark'
  # def test_multiple
  #   Benchmark.bmbm(30) do |bm|
  #     bm.report("encoding") {30000.times { test_encoding }}
  #     bm.report("decoding") {30000.times { test_decoding }}
  #     #bm.report("neighbors") {30000.times { test_neighbors }}
  #   end
  # end
end

