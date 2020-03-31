#include "ruby.h"
#include "gd.h"

VALUE resize_image(char *filename_in, char *filename_out, int w, int h, int image_type, int jpeg_quality);
VALUE wrap_resize_image(VALUE self, VALUE filename_in, VALUE filename_out, VALUE w, VALUE h, VALUE image_type, VALUE jpeg_quality);
void Init_fastimage_resize()
{
  VALUE module;
  module = rb_define_module("FastImageResize");
  rb_define_module_function(module, "resize_image", wrap_resize_image, 6);
}

VALUE wrap_resize_image(VALUE self, VALUE filename_in, VALUE filename_out, VALUE w, VALUE h, VALUE image_type, VALUE jpeg_quality) {
  char* _filename_in = RSTRING_PTR(filename_in);
  char* _filename_out = RSTRING_PTR(filename_out);
  int _w = FIX2INT(w);
  int _h = FIX2INT(h);
  int _image_type = FIX2INT(image_type);
  int _jpeg_quality = FIX2INT(jpeg_quality);
  return resize_image(_filename_in, _filename_out, _w, _h, _image_type, _jpeg_quality);
}

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