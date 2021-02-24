# frozen_string_literal: true

require 'simplecov'
require 'coveralls'
SimpleCov.start do
  add_filter 'spec'
end
Coveralls.wear!

require_relative '../lib/rndb'
