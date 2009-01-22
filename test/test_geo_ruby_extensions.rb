#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
require 'test/unit'
require 'test_helper'
require 'active_support'

class GeoRubyExtensionsTest < Test::Unit::TestCase
  
  include GeoRuby::SimpleFeatures

  def test_point_from_point
    start = Point.from_lon_lat(-76.511, 39.024)
    #p Point.from_point(start, 0, 10000)
  end
  
  def test_distance_calcs
    start = Point.from_lon_lat(-76.511, 39.024)
    0.upto(359) do |bearing|
      dest = start.point_at_bearing_and_distance(bearing, 10000)
      assert_in_delta 10000, start.ellipsoidal_distance(dest), 0.00001
    end
  end
end