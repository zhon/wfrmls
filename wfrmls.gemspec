# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wfrmls/version"

Gem::Specification.new do |s|
  s.name        = "wfrmls"
  s.version     = Wfrmls::VERSION
  s.authors     = ["zhon"]
  s.email       = ["zhon@xputah.org"]
  s.homepage    = ""
  s.summary     = %q{Helper for dealing with wfrmls.}
  s.description = s.summary

#t  s.rubyforge_project = "trusteesales"

  s.add_dependency 'watir'
  s.add_dependency 'configliere'
  s.add_dependency 'street_address_ext', '~> 0.0', '>= 0.0.3'
  s.add_dependency 'activesupport'
  s.add_dependency 'i18n'
  s.add_dependency 'nokogiri'

  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rr'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
