require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "fastimage_resize"
    s.summary = "FastImage Resize - Image resizing fast and simple"
    s.email = "sdsykes@gmail.com"
    s.homepage = "http://github.com/sdsykes/fastimage_resize"
    s.description = "FastImage Resize is an extremely light solution for resizing images in ruby by using libgd."
    s.authors = ["Stephen Sykes"]
    s.files = FileList["[A-Z]*", "{lib,test}/**/*"]
    s.extensions = "ext/fastimage_native_resize/extconf.rb"
    s.requirements << 'libgd, see www.libgd.org'
    s.add_dependency('fastimage', '>= 1.2.9')
    s.add_development_dependency('rake-compiler', '~> 0.9.9')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://
gems.github.com"
end

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/test.rb']
  t.warning = false
end

require "rake/extensiontask"

Rake::ExtensionTask.new "fastimage_native_resize"

Rake::Task[:test].prerequisites << :compile

task :default => :test
