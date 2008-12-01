class Test::Unit::TestCase
  def assert_points_equal(p1, p2)
    assert_in_delta p1.x, p2.x, 0.00001
    assert_in_delta p1.y, p2.y, 0.00001
  end
  
  def assert_coords_equal(c1, c2)
    0.upto(1) do |i|
      assert_in_delta c1[i], c2[i], 0.00001
    end
  end
end


