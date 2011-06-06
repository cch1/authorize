# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "authorize/version"

Gem::Specification.new do |s|
  s.name        = "authorize"
  s.version     = Authorize::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Hapgood"]
  s.email       = ["cch1@hapgoods.com"]
  s.homepage    = ""
  s.summary     = %q{A fast and flexible RBAC for Rails}
  s.description = %q{Authorize implements a full-blown Role-based Access Control (RBAC) system for Ruby on Rails}

  s.rubyforge_project = "authorize"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency('mocha', '~>0.9')
  s.add_development_dependency('sqlite3', '~>1.3')
  s.add_development_dependency('rails', '~>2.3.5')
  s.add_development_dependency('rake', '~>0.8.7')
  s.add_development_dependency('rdoc')
  s.add_dependency('redis', '~>2.1')
  s.add_dependency('activerecord', '~>2.3.5')
  s.add_dependency('actionpack', '~>2.3.5')
end