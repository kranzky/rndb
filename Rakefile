# frozen_string_literal: true

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'juwelier'
Juwelier::Tasks.new do |gem|
  gem.name = "rndb"
  gem.homepage = "https://github.com/kranzky/rndb"
  gem.license = "Unlicense"
  gem.summary = "RnDB is an procedurally-generated mock database."
  gem.description = ""
  gem.email = "lloyd@kranzky.com"
  gem.authors = ["Lloyd Kranzky"]
  gem.required_ruby_version = ">= 2.1"
end
Juwelier::RubygemsDotOrgTasks.new

require 'yard'
YARD::Rake::YardocTask.new

task default: :clean
