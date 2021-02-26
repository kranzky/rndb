# Generated by juwelier
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Juwelier::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rndb 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rndb".freeze
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lloyd Kranzky".freeze]
  s.date = "2021-02-26"
  s.description = "".freeze
  s.email = "lloyd@kranzky.com".freeze
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".document",
    ".editorconfig",
    ".github/workflows/ship.yml",
    ".github/workflows/test.yml",
    ".rdoc_options",
    ".rgignore",
    ".rspec",
    ".rubocop.yml",
    ".ruby-gemset",
    ".ruby-version",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/rndb.rb",
    "lib/rndb/database.rb",
    "lib/rndb/query.rb",
    "lib/rndb/slice.rb",
    "lib/rndb/table.rb",
    "lib/rndb/thicket.rb",
    "rndb.gemspec",
    "spec/rn_db/database_spec.rb",
    "spec/rn_db/query_spec.rb",
    "spec/rn_db/slice_spec.rb",
    "spec/rn_db/table_spec.rb",
    "spec/rn_db/thicket_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "https://github.com/kranzky/rndb".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.0.8".freeze
  s.summary = "RnDB is an procedurally-generated mock database.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rdoc>.freeze, ["~> 6.3"])
      s.add_runtime_dependency(%q<yard>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.17"])
      s.add_development_dependency(%q<gemfile_updater>.freeze, ["~> 0.1"])
      s.add_development_dependency(%q<juwelier>.freeze, ["~> 2.4"])
      s.add_development_dependency(%q<byebug>.freeze, ["~> 11.1"])
      s.add_development_dependency(%q<crypt-isaac>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<faker>.freeze, ["~> 2.16"])
    else
      s.add_dependency(%q<rdoc>.freeze, ["~> 6.3"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.17"])
      s.add_dependency(%q<gemfile_updater>.freeze, ["~> 0.1"])
      s.add_dependency(%q<juwelier>.freeze, ["~> 2.4"])
      s.add_dependency(%q<byebug>.freeze, ["~> 11.1"])
      s.add_dependency(%q<crypt-isaac>.freeze, ["~> 1.2"])
      s.add_dependency(%q<faker>.freeze, ["~> 2.16"])
    end
  else
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.3"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.17"])
    s.add_dependency(%q<gemfile_updater>.freeze, ["~> 0.1"])
    s.add_dependency(%q<juwelier>.freeze, ["~> 2.4"])
    s.add_dependency(%q<byebug>.freeze, ["~> 11.1"])
    s.add_dependency(%q<crypt-isaac>.freeze, ["~> 1.2"])
    s.add_dependency(%q<faker>.freeze, ["~> 2.16"])
  end
end

