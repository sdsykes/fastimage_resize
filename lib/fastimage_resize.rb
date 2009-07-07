# FastImageResize is an extremely light solution for resizing images in ruby by using libgd
#
# === Examples
#   require 'fastimage_resize'
#
#   FastImageResize.resize("http://stephensykes.com/images/ss.com_x.gif", "my.gif", 100, 20)
#   => true
#
# === References
# * http://blog.new-bamboo.co.uk/2007/12/3/super-f-simple-resizing
#

require 'inline'
require 'open-uri'
require 'tempfile'
require 'fastimage'

class FastImageResize
  SUPPORTED_FORMATS = [:jpg, :png, :gif]

  class FastImageResizeException < StandardError # :nodoc:
  end
  class NotSupported < FastImageResizeException # :nodoc:
  end
  class FetchError < FastImageResizeException # :nodoc:
  end
  
  def resize_image(filename_in, filename_out, w, h, image_type, jpeg_quality); end
  
  def self.resize(uri_in, file_out, w, h, options={})
    jpeg_quality = options[:jpeg_quality] || -1
    
    u = URI.parse(uri_in)
    if u.scheme == "http" || u.scheme == "ftp" || u.scheme == "https"
      f = Tempfile.new(name)
      f.write(open(u).read)
      f.close
      resize_local(f.path, file_out, w, h, jpeg_quality)
      File.unlink(f.path)
    else
      resize_local(uri_in, file_out, w, h, jpeg_quality)
    end
  rescue OpenURI::HTTPError, SocketError, FastImage::ImageFetchFailure
    raise FetchError
  end

  def self.resize_local(file_in, file_out, w, h, jpeg_quality)
    type_index = SUPPORTED_FORMATS.index(FastImage.type(file_in, :raise_on_failure=>true))
    raise NotSupported unless type_index
    new.resize_image(file_in, file_out, w, h, type_index, jpeg_quality)
  end

  inline do |builder|
    builder.include '"gd.h"'
    builder.add_link_flags "-lgd"
    
    builder.c <<-"END"
      void resize_image(char *filename_in, char *filename_out, int w, int h, int image_type, int jpeg_quality) {
        gdImagePtr im_in, im_out;
        FILE *in, *out;
        int trans, trans_r, trans_g, trans_b;
        int x, y, f = 0;

        in = fopen(filename_in, "rb");
        if (!in) return;

        im_out = gdImageCreateTrueColor(w, h);  /* must be truecolor */
        switch(image_type) {
          case 0: im_in = gdImageCreateFromJpeg(in);
                  break;
          case 1: im_in = gdImageCreateFromPng(in);
                  gdImageAlphaBlending(im_out, 0);  /* handle transparency correctly */
                  gdImageSaveAlpha(im_out, 1);
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
      }
    END
  end
end
