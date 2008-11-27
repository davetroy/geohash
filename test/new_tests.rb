#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
require 'test/unit'
 
class GeoHashTest < Test::Unit::TestCase
  
  include GeoRuby::SimpleFeatures
 
  def assert_points_equal(p1, p2)
    assert_equal p1.x.to_s, p2.x.to_s
    assert_equal p1.y.to_s, p2.y.to_s
  end
     
  def test_encoding
    assert_equal "dqcw4bn7k2", GeoHash.new(Point.from_lon_lat(-76.511,39.024)).to_s
    assert_points_equal Point.from_lon_lat(-76.5110045671463,39.0239980816841), GeoHash.new("dqcw4bn7k2").center
  end
end