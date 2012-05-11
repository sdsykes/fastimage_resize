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

require 'inline'
require 'open-uri'
require 'tempfile'
require 'fastimage'

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
      u = URI.parse(input)
      if u.scheme == "http" || u.scheme == "https" || u.scheme == "ftp"
        file_in = read_to_local(open(u))
      else
        file_in = input.to_s
      end
    end

    fast_image = new(file_in, :raise_on_failure=>true)
    type_index = SUPPORTED_FORMATS.index(fast_image.type)
    raise FormatNotSupported unless type_index

    if !file_out
      temp_file = Tempfile.new([name, ".#{FILE_EXTENSIONS[type_index]}"])
      file_out = temp_file.path
    else
      temp_file = nil
    end

    in_path = file_in.respond_to?(:path) ? file_in.path : file_in

    fast_image.resize_image(in_path, file_out.to_s, w.to_i, h.to_i, type_index, jpeg_quality.to_i)

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
    temp.write(readable.read)
    temp.close
    temp.open
    temp
  end

  def resize_image(filename_in, filename_out, w, h, image_type, jpeg_quality); end
  
  inline do |builder|
    builder.include '"gd.h"'
    builder.add_link_flags "-lgd"
    
    builder.c <<-"END"
      VALUE resize_image(char *filename_in, char *filename_out, int w, int h, int image_type, int jpeg_quality) {
        gdImagePtr im_in, im_out;
        FILE *in, *out;
        int trans = 0, x = 0, y = 0, f = 0;

        in = fopen(filename_in, "rb");
        if (!in) return Qnil;

        switch(image_type) {
          case 0: im_in = gdImageCreateFromJpeg(in);
                  break;
          case 1: im_in = gdImageCreateFromPng(in);
                  break;
          case 2: im_in = gdImageCreateFromGif(in);
                  trans = gdImageGetTransparent(im_in);
                  /* find a transparent pixel, then turn off transparency
                     so that it copies correctly */
                  if (trans >= 0) {
                    for (x=0; x<gdImageSX(im_in); x++) {
                      for (y=0; y<gdImageSY(im_in); y++) {
                        if (gdImageGetPixel(im_in, x, y) == trans) {
                          f = 1;
                          break;
                        }
                      }
                      if (f) break;
                    }
                    gdImageColorTransparent(im_in, -1);
                    if (!f) trans = -1;  /* no transparent pixel found */
                  }
                  break;
          default: return Qnil;
        }

        if (w == 0 || h == 0) {
          int originalWidth  = gdImageSX(im_in);
          int originalHeight = gdImageSY(im_in);
          if (w == 0) {
            w = (int)(h * originalWidth / originalHeight);
          } else {
            h = (int)(w * originalHeight / originalWidth);
          }
        }

        im_out = gdImageCreateTrueColor(w, h);  /* must be truecolor */

        if (image_type == 1) {
          gdImageAlphaBlending(im_out, 0);  /* handle transparency correctly */
          gdImageSaveAlpha(im_out, 1);
        }
        
        fclose(in);
        
        /* Now copy the original */
        gdImageCopyResampled(im_out, im_in, 0, 0, 0, 0,
          gdImageSX(im_out), gdImageSY(im_out),
          gdImageSX(im_in), gdImageSY(im_in));

        out = fopen(filename_out, "wb");
        if (out) {
          switch(image_type) {
            case 0: gdImageJpeg(im_out, out, jpeg_quality);
                    break;
            case 1: gdImagePng(im_out, out);
                    break;
            case 2: gdImageTrueColorToPalette(im_out, 0, 256);
                    if (trans >= 0) {
                      trans = gdImageGetPixel(im_out, x, y);  /* get the color index of our transparent pixel */
                      gdImageColorTransparent(im_out, trans); /* may not always work as hoped */
                    }
                    gdImageGif(im_out, out);
                    break;
          }
          fclose(out);
        }
        gdImageDestroy(im_in);
        gdImageDestroy(im_out);
        return Qnil;
      }
    END
  end
end
