require 'rubygems'

require 'test/unit'

PathHere = File.dirname(__FILE__)

require File.join(".", PathHere, "..", "lib", 'fastimage_resize')

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

TestUrl = "http://www.example.nowhere/"

GoodFixtures.each do |fn, info|
  FakeWeb.register_uri(:get, "#{TestUrl}#{fn}", :body => File.join(FixturePath, fn))
end
BadFixtures.each do |fn|
  FakeWeb.register_uri(:get, "#{TestUrl}#{fn}", :body => File.join(FixturePath, fn))
end

redirect_response = <<END
HTTP/1.1 302 Found
Date: Tue, 27 Sep 2011 09:47:50 GMT
Server: Apache/2.2.11
Location: https://somwehere.example.com/a.gif
Status: 302
END
FakeWeb.register_uri(:get, "#{TestUrl}/redirect", :response=>redirect_response)

class FastImageResizeTest < Test::Unit::TestCase
  def test_resize_image_types_from_http
    GoodFixtures.each do |fn, info|
      outfile = File.join(PathHere, "fixtures", "resized_" + fn)
      FastImage.resize(TestUrl + fn, info[1][0] / 3, info[1][1] / 2, :outfile=>outfile)
      assert_equal [info[1][0] / 3, info[1][1] / 2], FastImage.size(outfile)
      File.unlink outfile
    end
  end

  def test_resize_image_types_from_files
    GoodFixtures.each do |fn, info|
      outfile = File.join(PathHere, "fixtures", "resized_" + fn)
      FastImage.resize(File.join(FixturePath, fn), info[1][0] / 3, info[1][1] / 2, :outfile=>outfile)
      assert_equal [info[1][0] / 3, info[1][1] / 2], FastImage.size(outfile)
      File.unlink outfile
    end
  end

  def test_resize_image_types_from_io_objects
    GoodFixtures.each do |fn, info|
      outfile = File.join(PathHere, "fixtures", "resized_" + fn)
      File.open(File.join(FixturePath, fn)) do |io|
        FastImage.resize(io, info[1][0] / 3, info[1][1] / 2, :outfile=>outfile)
        assert_equal [info[1][0] / 3, info[1][1] / 2], FastImage.size(outfile)
        File.unlink outfile
      end
    end
  end

  def test_resize_to_temp_file
    GoodFixtures.each do |fn, info|
      File.open(File.join(FixturePath, fn)) do |io|
        outfile = FastImage.resize(io, info[1][0] / 3, info[1][1] / 2)
        assert_equal [info[1][0] / 3, info[1][1] / 2], FastImage.size(outfile)
      end
    end
  end

  def test_should_raise_for_bmp_files
    fn = BadFixtures[0]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::FormatNotSupported) do
      FastImage.resize(TestUrl + fn, 20, 20, :outfile=>outfile)
    end
  end
  
  def test_should_raise_for_faulty_files
    fn = BadFixtures[1]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::SizeNotFound) do
      FastImage.resize(TestUrl + fn, 20, 20, :outfile=>outfile)
    end
  end
  
  def test_should_raise_for_ico_files
    fn = BadFixtures[2]
    outfile = File.join(PathHere, "fixtures", "resized_" + fn)
    assert_raises(FastImage::FormatNotSupported) do
      FastImage.resize(TestUrl + fn, 20, 20, :outfile=>outfile)
    end
  end
  
  def test_should_raise_for_invalid_uri
    assert_raises(FastImage::ImageFetchFailure) do
      FastImage.resize("#{TestUrl}////%&redirect", 20, 20)
    end
  end
  
  def test_should_raise_for_redirect
    assert_raises(FastImage::ImageFetchFailure) do
      FastImage.resize("#{TestUrl}/redirect", 20, 20)
    end
  end
  
  def test_resized_jpg_is_reasonable_size_for_quality
    outfile = File.join(PathHere, "fixtures", "resized_test.jpg")
    FastImage.resize(File.join(FixturePath, "test.jpg"), 200, 200, :outfile=>outfile)
    size = File.size(outfile)
    assert size < 30000
    assert size > 10000
    FastImage.resize(File.join(FixturePath, "test.jpg"), 200, 200, :outfile=>outfile, :jpeg_quality=>5)
    size = File.size(outfile)
    assert size < 3500
    assert size > 1500
    File.unlink outfile
  end
  
  def test_output_tempfile_has_right_extension
    outfile = FastImage.resize(File.join(FixturePath, "test.jpg"), 200, 200)
    assert outfile.path =~ /\.jpg$/
    outfile = FastImage.resize(File.join(FixturePath, "test.gif"), 200, 200)
    assert outfile.path =~ /\.gif$/
    outfile = FastImage.resize(File.join(FixturePath, "test.png"), 200, 200)
    assert outfile.path =~ /\.png$/
  end

  def test_zero_width_scales_proportionately
    GoodFixtures.each do |fn, info|
      File.open(File.join(FixturePath, fn)) do |io|
        halfHeight = (info[1][1] / 2).round
        outfile = FastImage.resize(io, 0, halfHeight)
        newWidth = (halfHeight * info[1][0] / info[1][1]).round
        assert_equal [newWidth, halfHeight], FastImage.size(outfile)
      end
    end
  end

  def test_zero_height_scales_proportionately
    GoodFixtures.each do |fn, info|
      File.open(File.join(FixturePath, fn)) do |io|
        halfWidth =  (info[1][0] / 2).round
        outfile = FastImage.resize(io, halfWidth, 0)
        newHeight = (halfWidth * info[1][1] / info[1][0]).round
        assert_equal [halfWidth, newHeight], FastImage.size(outfile)
      end
    end
  end
end
