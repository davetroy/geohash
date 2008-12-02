#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
require 'test/unit'
require 'test_helper'
require 'active_support'

class GeoHashTest < Test::Unit::TestCase
  
  include GeoRuby::SimpleFeatures

  def test_initialization_modes
    assert_equal "dqcw4bn7k2", GeoHash.new(Point.from_lon_lat(-76.511,39.024)).to_s
    assert_points_equal Point.from_lon_lat(-76.5110045671463,39.0239980816841), GeoHash.new("dqcw4bn7k2").center
    assert_points_equal Point.from_lon_lat(-76.500, 39.02400), GeoHash.new(-76.500, 39.02400).center
  end
  
  def test_neighbors
    gh = GeoHash.new(-76.511,39.024,7)
    neighbor_hashes = gh.neighbors.map { |n| n.to_s }
    assert_equal ["dqctfzy","dqctfzz","dqcw4bp","dqcw4bq","dqcw4br","dqcw4bj","dqctfzv","dqcw4bm"].to_set, neighbor_hashes.to_set
  end
  
  def test_contains
    p1 = GeoHash.new("dqcw4bn7k2")
    p2 = GeoHash.new("dqcw4")
    assert p2.contains?(p1.center)
  end
  
  def test_largest_parent
    gh = GeoHash.new(-76.511, 39.024, 10)
    assert_equal "dqcw4b", gh.largest_parent_within_radius(1000).to_s
    assert_equal "dqcw4", gh.largest_parent_within_radius(10000).to_s
    assert_equal "dqcw", gh.largest_parent_within_radius(100000).to_s
    assert_equal "dqc", gh.largest_parent_within_radius(200000).to_s
  end
  
  def test_neighbors_within_radius
    gh = GeoHash.new(-76.511, 39.024, 9)
    nlist = gh.neighbors_within_radius(50).map { |n| n.to_s }
    assert_equal nlist.size, nlist.uniq.size
  end
  
  def test_neighbors_in_range
    gh = GeoHash.new(-76.511, 39.024, 5)
    #p gh.neighbors_in_range(10000)
  end
end

