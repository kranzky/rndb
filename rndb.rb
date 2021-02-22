#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'
require 'byebug'
require 'json'

DISTRIBUTIONS = {
  colour: {
    red: 0.3,
    green: 0.1,
    brown: 0.01,
    blue: 0.5,
    orange: 0.09
  },
  transparent: {
    true => 0.1,
    false => 0.9
  },
  weight: {
    light: 0.3,
    medium: 0.6,
    heavy: 0.1
  },
  material: {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
}

SIZE = 1_000_000

module RN
  class DB
    def initialize(seed=Time.now.to_i)
      @seed = seed

      DISTRIBUTIONS.each do |label, distribution|
        raise unless distribution.values.sum == 1
      end

      @mapping = Hash.new do |mapping, property|
        mapping[property] = Hash.new do |distribution, value|
          distribution[value] = {
            length: 0,
            ranges: []
          }
        end
      end

      ranges = [(0...SIZE)]
      DISTRIBUTIONS.each do |label, distribution| 
        ranges = _add_mapping(label, distribution, ranges)
        puts JSON.pretty_generate(@mapping)
      end
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

    def _add_mapping(label, distribution, ranges)
      ranges.each do |range|
        start = range.first
        distribution.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[label][value][:ranges] << (start...start+length)
          start += length
        end
      end
      ranges.clear
      @mapping[label].each do |value, distribution|
        ranges << distribution[:ranges]
        distribution[:length] = distribution[:ranges].map(&:count).sum
      end
      ranges.flatten
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
