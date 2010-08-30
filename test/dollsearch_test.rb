require 'test_helper'

class DollSearchTest < Test::Unit::TestCase
 	include DollSearch

	def test_assert_invalid_file
		assert_raise(DollSearch::InvalidFileName) { Doll.scan("#{Dir.pwd}/test/images/face2.jpg") }
	end

	def test_assert_dollface_detected
		assert true if Doll.scan("#{Dir.pwd}/test/images/face.jpg")
  end

	def test_assert_dollface_not_detected
		assert false if Doll.scan("#{Dir.pwd}/test/images/car.jpg")
	end
end
