require "mkmf"

abort "missing libgd" unless have_library("gd")

create_makefile "fastimage_native_resize"
