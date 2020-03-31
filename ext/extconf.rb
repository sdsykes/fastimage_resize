require 'mkmf'
funcs = [
  "gdImageCreateFromJpeg",
  "gdImageCreateFromPng" ,
  "gdImageCreateFromGif",
  # "gdImageGetTransparent", macro
  # "gdImageSX", macro
  # "gdImageSY", macro
  "gdImageGetPixel",
  "gdImageColorTransparent",
  "gdImageCreateTrueColor",
  "gdImageAlphaBlending",
  "gdImageSaveAlpha",
  "gdImageCopyResampled",
  "gdImageJpeg",
  "gdImagePng",
  "gdImageGif",
  "gdImageDestroy"
]
dir_config("gd")
if have_header("gd.h") and funcs.all? {|v| have_library("gd", v) }
  create_makefile('fastimage_resize')
end  