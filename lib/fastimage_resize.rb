# FastImage Resize is an extremely light solution for resizing images in ruby by using libgd
#
# === Examples
#
#   require 'fastimage_resize'
#
#   FastImage.resize("http://stephensykes.com/images/ss.com_x.gif", 100, 20, :outfile=>"my.gif")
#   => 1
#
# === Requirements
#
# RubyInline
#
#   gem install RubyInline
#
# FastImage
#
#   gem install fastimage
#
# Libgd
#
# See http://www.libgd.org/
# Libgd is commonly available on most unix platforms, including OSX. 
#
# === References
#
# * http://blog.new-bamboo.co.uk/2007/12/3/super-f-simple-resizing

require "fastimage_resize/fastimage_resize"
require 'open-uri'
require 'tempfile'
require "fastimage"

class FastImage
  SUPPORTED_FORMATS = [:jpeg, :png, :gif]
  FILE_EXTENSIONS = [:jpg, :png, :gif]  # prefer jpg to jpeg as an extension

  class FormatNotSupported < FastImageException # :nodoc:
  end
  
  # Resizes an image, storing the result in a file given in file_out
  #
  # Input can be a filename, a uri, or an IO object.
  #
  # FastImage Resize can resize GIF, JPEG and PNG files.
  #
  # Giving a zero value for width or height causes the image to scale proportionately.
  #
  # === Example
  #
  #   require 'fastimage_resize'
  #
  #   FastImage.resize("http://stephensykes.com/images/ss.com_x.gif", 100, 20, :outfile=>"my.gif")
  #
  # === Supported options
  # [:jpeg_quality]
  #   A figure passed to libgd to determine quality of output jpeg (only useful if input is jpeg)
  # [:outfile]
  #   Name of a file to store the output in, in this case a temp file is not used
  #
  def self.resize(input, w, h, options={})
    jpeg_quality = options[:jpeg_quality] || -1
    file_out = options[:outfile]
    
    if input.respond_to?(:read)
      file_in = read_to_local(input)
    else
      if input =~ URI.regexp(['http','https','ftp'])
        u = URI.parse(input)
        file_in = read_to_local(URI.open(u))
      else
        file_in = input.to_s
      end
    end
    fast_image = new(file_in, :raise_on_failure=>true)
    type_index = SUPPORTED_FORMATS.index(fast_image.type)
    raise FormatNotSupported unless type_index

    if !file_out
      temp_file = Tempfile.new([name, ".#{FILE_EXTENSIONS[type_index]}"])
      temp_file.binmode
      file_out = temp_file.path
    else
      temp_file = nil
    end

    in_path = file_in.respond_to?(:path) ? file_in.path : file_in

    FastImageResize.resize_image(in_path, file_out.to_s, w.to_i, h.to_i, type_index, jpeg_quality.to_i)

    if file_in.respond_to?(:close)
      file_in.close
      file_in.unlink
    end

    temp_file
  rescue OpenURI::HTTPError, SocketError, URI::InvalidURIError, RuntimeError => e
    raise ImageFetchFailure, e.class
  end

  private

  # returns readable tempfile
  def self.read_to_local(readable)
    temp = Tempfile.new(name)
    temp.binmode
    temp.write(readable.read)
    temp.close
    temp.open
    temp
  end

end
