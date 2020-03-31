require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "fastimage_resize"
    s.summary = "FastImage Resize - Image resizing fast and simple"
    s.email = "do-not-send@loilo.tv"
    s.homepage = "http://github.com/loilo-inc/fastimage_resize"
    s.description = "FastImage Resize is an extremely light solution for resizing images in ruby by using libgd."
    s.authors = ["Stephen Sykes", "Yusuke Sakurai"]
    s.files = FileList["[A-Z]*", "{ext,lib,test}/**/*"]
    s.requirements << 'libgd, see www.libgd.org'
    s.add_dependency('fastimage', '>= 1.2.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://
gems.github.com"
end
