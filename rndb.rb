#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'
require 'byebug'
require 'json'

COLOUR = {
  red: 0.3,
  green: 0.1,
  brown: 0.01,
  blue: 0.5,
  orange: 0.09
}

TRANSPARENT = {
  true => 0.1,
  false => 0.9
}

WEIGHT = {
  light: 0.3,
  medium: 0.6,
  heavy: 0.1
}

MATERIAL = {
  leather: 0.2,
  steel: 0.4,
  wood: 0.3,
  fluff: 0.1
}

SIZE = 1_000_000

module RN
  class DB
    def initialize(seed=Time.now.to_i)
      @seed = seed

      raise unless COLOUR.values.sum == 1
      raise unless TRANSPARENT.values.sum == 1
      raise unless WEIGHT.values.sum == 1
      raise unless MATERIAL.values.sum == 1

      @mapping = Hash.new do |mapping, property|
        mapping[property] = Hash.new do |distribution, value|
          distribution[value] = {
            length: 0,
            ranges: []
          }
        end
      end

      ranges = [(0...SIZE)]
      ranges.each do |range|
        start = range.first
        COLOUR.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[:colour][value][:ranges] << (start...start+length)
          start += length
        end
      end
      @mapping[:colour].each do |value, distribution|
        distribution[:length] = distribution[:ranges].map(&:count).sum
      end

      puts JSON.pretty_generate(@mapping)

      ranges =
        @mapping[:colour].values.map do |distribution|
          distribution[:ranges]
        end.flatten
      ranges.each do |range|
        start = range.first
        TRANSPARENT.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[:transparent][value][:ranges] << (start...start+length)
          start += length
        end
      end
      @mapping[:transparent].each do |value, distribution|
        distribution[:length] = distribution[:ranges].map(&:count).sum
      end

      ranges =
        @mapping[:transparent].values.map do |distribution|
          distribution[:ranges]
        end.flatten
      ranges.each do |range|
        start = range.first
        WEIGHT.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[:weight][value][:ranges] << (start...start+length)
          start += length
        end
      end
      @mapping[:weight].each do |value, distribution|
        distribution[:length] = distribution[:ranges].map(&:count).sum
      end
      
      puts JSON.pretty_generate(@mapping)
      ranges =
        @mapping[:weight].values.map do |distribution|
          distribution[:ranges]
        end.flatten
      ranges.each do |range|
        start = range.first
        MATERIAL.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[:material][value][:ranges] << (start...start+length)
          start += length
        end
      end
      @mapping[:material].each do |value, distribution|
        distribution[:length] = distribution[:ranges].map(&:count).sum
      end
      
      puts JSON.pretty_generate(@mapping)
    end

    def generate(table, row)
      raise unless (0...SIZE).include?(row)
      case table
      when :ball
        _generate_ball(row)
      when :person
        _generate_person(row)
      end
    end

    private

    def _generate_ball(row)
      {
        colour: _generate_colour(row),
        transparent: _generate_transparent(row),
        weight: _generate_weight(row),
        material: _generate_material(row)
      }
    end

    def _generate_person(row)
      {
        sex: _generate_sex(row),
        age: _generate_age(row),
        race: _generate_race(row),
        name: _generate_name(row),
        spouse: _generate_spouse(row)
      }
    end

    def _generate_colour(row)
      _seed(:ball, :colour, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_transparent(row)
      _seed(:ball, :transparent, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_weight(row)
      _seed(:ball, :weight, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_material(row)
      _seed(:ball, :material, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_sex(row)
      _seed(:person, :sex, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_age(row)
      _seed(:person, :sex, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_race(row)
      _seed(:person, :race, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_name(row)
      _seed(:person, :name, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_spouse(row)
      _seed(:person, :spouse, row)
      Crypt::ISAAC.rand(100)
    end

    def _seed(table, col, row)
      value = [@seed, table, col, row].join('-')
      digest = Digest::SHA256.hexdigest(value)
      retval = digest.to_i(16) % 18446744073709551616
      Crypt::ISAAC.srand(retval)
      nil
    end
  end

  class Table
    include Comparable

    def initialize
      @attributes = {}
    end

    def <=>(other)
      self.id <=> other.id
    end

    def save
    end
  end

  class Query
    include Enumerable

    def each
      raise
    end
  end
end

SEED = 137
DB = RN::DB.new(SEED)
puts DB.generate(:ball, 0)
puts DB.generate(:ball, 1)
puts DB.generate(:person, 0)
