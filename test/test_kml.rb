#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext"
require "#{File.dirname(__FILE__)}/../lib/geohash"
# require 'test/unit'
# require 'test_helper'

require 'active_support'
require 'builder'

def make_polygon(n)
  points = n.four_corners
  points << points.first
  points.map { |p| [p.x, p.y, 100].join(',') }.join("\n")
end

include GeoRuby::SimpleFeatures
  
gh = GeoHash.new(-76.511, 39.024, 6)
#@matrix = gh.neighbors_within_radius(14000)
#@matrix = gh.children_within_radius(2500)
#@matrix = gh.neighbors_in_range(8000)
gh = GeoHash.new(-76.511,39.024,7)
#@matrix = gh.surrounding_matrix(9)
cell_centers = gh.all_nth_neighbors(3) << gh
@matrix = cell_centers.map { |c| [c, c.neighbors] }.flatten

File.open("./foo.kml", 'w') do |f|
  xml = Builder::XmlMarkup.new(:target => f, :indent => 1)
  xml.kml("xmlns" => "http://earth.google.com/kml/2.2", 
  "xmlns:atom" => "http://www.w3.org/2005/Atom") do
    xml.tag! "Document" do
      xml.tag! "Style", :id => "transBluePoly" do
        xml.tag! "LineStyle" do
          xml.width 1.5
        end
        xml.tag! "PolyStyle" do
          xml.color "7dff0000"
        end
      end
      lastdec = 0
      @matrix.each do |n|
        xml.tag! "Placemark", :id => n.value do
          xml.styleUrl "#transBluePoly"
          xml.name n.value
          xml.tag! "Polygon" do
            xml.extrude 1
            xml.altitudeMode 'relativeToGround'
            xml.tag! "outerBoundaryIs" do
              xml.tag! "LinearRing" do
                xml.coordinates make_polygon(n)
              end
            end
          end
        end
      end
      
      
    end
  end
end