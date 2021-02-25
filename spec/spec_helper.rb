# frozen_string_literal: true

require 'simplecov'
require 'coveralls'
SimpleCov.start do
  add_filter 'spec'
end
Coveralls.wear!

require 'faker'
require_relative '../lib/rndb'

class Ball < RnDB::Table
  column :colour, {
    red: 0.3,
    green: 0.1,
    brown: 0.01,
    blue: 0.5,
    orange: 0.09
  }
  column :transparent, {
    true => 0.1,
    false => 0.9
  }
  column :weight, {
    light: 0.3,
    medium: 0.6,
    heavy: 0.1
  }, lambda { |value|
    lookup = {
      light: (0.1..3.0),
      medium: (3.0..6.0),
      heavy: (6.0..9.9)
    }
    self.rand(lookup[value])
  }
  column :material, {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
  column :name, -> { Faker::Games::Pokemon.name }
  column :location, -> { Faker::Games::Pokemon.location }
  column :move, -> { Faker::Games::Pokemon.move }
end
