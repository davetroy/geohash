Gem::Specification.new do |s|
  s.name     = "geohash"
  s.version  = '1.1.0'
  s.date     = "2008-11-27"
  s.summary  = "GeoHash Library for Ruby, per http://geohash.org implementation"
  s.email    = "dave@roundhousetech.com"
  s.homepage = "http://github.com/davetroy/geohash"
  s.description = "Geohash provides support for manipulating GeoHash strings in Ruby. See http://geohash.org."
  s.has_rdoc = true
  s.authors  = ["David Troy"]
  s.files    = ["ext/extconf.rb", 
		"ext/geohash_native.c",
		"lib/geohash.rb"]
  s.test_files = ["test/test_geohash.rb"]
  s.rdoc_options = ["--main", "README"]
  s.extensions << 'ext/extconf.rb'
  s.extra_rdoc_files = ["Manifest.txt", "README"]
end