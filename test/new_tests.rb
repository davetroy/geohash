#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
require 'test/unit'
 
class GeoHashTest < Test::Unit::TestCase
  
  include GeoRuby::SimpleFeatures
 
  def test_encoding
    gh = GeoHash.from_point(Point.from_x_y(-76.511,39.024))
    p gh
    p gh.value
  end
end