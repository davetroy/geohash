#!/usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
require 'test/unit'

class GeoHashTest < Test::Unit::TestCase
  
  def test_decoding
    assert_equal [39.02474, -76.51100], GeoHash.decode("dqcw4bnrs6s7")
    assert_equal [37.791562, -122.398541], GeoHash.decode("9q8yyz8pg3bb", 6)
    assert_equal [37.791562, -122.398541], GeoHash.decode("9Q8YYZ8PG3BB", 6)
    assert_equal [42.60498046875, -5.60302734375], GeoHash.decode("ezs42", 11)
    assert_equal [-25.382708, -49.265506], GeoHash.decode("6gkzwgjzn820",6)
    assert_equal [-25.383, -49.266], GeoHash.decode("6gkzwgjz", 3)
    assert_equal [37.8565, -122.2554], GeoHash.decode("9q9p658642g7", 4)
  end

  def test_encoding
    assert_equal "dqcw4bnrs6s7", GeoHash.encode(39.0247389581054, -76.5110040642321, 12)
    assert_equal "dqcw4bnrs6", GeoHash.encode(39.0247389581054, -76.5110040642321, 10)
    assert_equal "6gkzmg1u", GeoHash.encode(-25.427, -49.315, 8)
    assert_equal "ezs42", GeoHash.encode(42.60498046875, -5.60302734375, 5)
  end

  def check_decoding(gh)
    exact = GeoHash.decode(gh, 20)
    bbox = GeoHash.decode_bbox(gh)

    # check that the bbox is centered on the decoded point
    bbox_center = [(bbox[0][0] + bbox[1][0]) / 2, (bbox[0][1] + bbox[1][1]) / 2]
    assert_equal exact, bbox_center

    # check that the bounding box is the expected size
    bits = gh.size * 5
    lon_bits = (bits.to_f/2).ceil
    lat_bits = (bits.to_f/2).floor
    correct_size = [180.0/2**lat_bits, 360.0/2**lon_bits]
    bbox_size = [bbox[1][0] - bbox[0][0], bbox[1][1] - bbox[0][1]]
    assert_equal bbox_size, correct_size
  end

  def test_decoding_bbox
    s = "dqcw4bnrs6s7"
    (s.length).downto(0) do |l|
      check_decoding(s[0..l])
    end
  end
  
  def test_specific_bbox
    assert_equal [[39.0234375, -76.552734375], [39.0673828125, -76.5087890625]], GeoHash.decode_bbox('dqcw4')
  end
  
  def test_neighbors
    assert_equal ["dqcjr1", "dqcjq9", "dqcjqf", "dqcjqb", "dqcjr4", "dqcjr0", "dqcjqd", "dqcjq8"], GeoHash.new("dqcjqc").neighbors

    assert_equal "dqcw5", GeoHash.calculate_adjacent("dqcw4", 0)  # right
    assert_equal "dqcw1", GeoHash.calculate_adjacent("dqcw4", 1)  # left
    
    assert_equal "dqctc", GeoHash.calculate_adjacent("dqcw1", 3)  # bottom

    assert_equal "dqcwh", GeoHash.calculate_adjacent("dqcw5", 0)  # right
    assert_equal "dqcw4", GeoHash.calculate_adjacent("dqcw5", 1)  # left
    assert_equal "dqcw7", GeoHash.calculate_adjacent("dqcw5", 2)  # top
    assert_equal "dqctg", GeoHash.calculate_adjacent("dqcw5", 3)  # bottom
    assert_equal 8, (["dqcw7", "dqctg", "dqcw4", "dqcwh", "dqcw6", "dqcwk", "dqctf", "dqctu"] & GeoHash.new("dqcw5").neighbors).size
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

