# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fastimage_resize}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephen Sykes"]
  s.date = %q{2009-07-10}
  s.description = %q{FastImage Rssize is an extremely light solution for resizing images in ruby by using libgd.}
  s.email = %q{sdsykes@gmail.com}
  s.extra_rdoc_files = ["README", "README.textile"]
  s.files = ["Rakefile", "README", "README.textile", "VERSION.yml", "lib/fastimage_resize.rb", "test/test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/sdsykes/fastimage_resize}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{FastImage Resize - Image resizing fast and simple}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
