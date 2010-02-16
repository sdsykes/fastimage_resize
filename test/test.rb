require 'rubygems'

require 'test/unit'

PathHere = File.dirname(__FILE__)

require File.join(PathHere, "..", "lib", 'fastimage_resize')

require 'fakeweb'

FixturePath = File.join(PathHere, "fixtures")

GoodFixtures = {
  "test.gif"=>[:gif, [17, 32]],
  "test.jpg"=>[:jpeg, [882, 470]],
  "test.png"=>[:png, [30, 20]]
  }

BadFixtures = [
  "test.bmp",
  "faulty.jpg",
  "test.ico"
]

TestUrl = "http://example.nowhere/"

GoodFixtures.each do |fn, info|
  FakeWeb.register_uri(:get, "#{TestUrl}#{fn}", :body => File.join(FixturePath, fn))
end
BadFixtures.each do |fn|
  FakeWeb.register_uri(:get, "#{TestUrl}#{fn}", :body => File.join(FixturePath, fn))
end

class FastImageResizeTest < Test::Unit::TestCase
  def test_resize_image_types
    GoodFixtures.each do |fn, info|
      outfile = File.join(PathHere, "fixtures", "resized_" + fn)
      FastImage.resize(TestUrl + fn, outfile, info[1][0] / 3, info[1][1] / 2)
      assert_equal [info[1][0] / 3, info[1][1] / 2], FastImage.size(outfile)
      File.unlink outfile
    end
  end

  def test_should_raise_for_bmp_files
    fn = BadFixtures[0]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::FormatNotSupported) do
      FastImage.resize(TestUrl + fn, outfile, 20, 20)
    end
  end
  
  def test_should_raise_for_faulty_files
    fn = BadFixtures[1]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::SizeNotFound) do
      FastImage.resize(TestUrl + fn, outfile, 20, 20)
    end
  end
  
  def test_should_raise_for_ico_files
    fn = BadFixtures[2]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::UnknownImageType) do
      FastImage.resize(TestUrl + fn, outfile, 20, 20)
    end
  end
  
end
