# frozen_string_literal: true

require 'digest'

module RnDB
  class Table
    class << self
      include Enumerable
    end

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def attributes
      _generate_all
    end

    def to_h
      attributes
    end

    def to_s
      to_h.to_s
    end

    def self.table_name
      name.downcase.to_sym
    end

    def self.[](index)
      self.new(index) if index < count
    end

    def self.where(constraints={})
      ids = [Slice.new(0, _schema[:size] - 1)]
      constraints.each do |property, values|
        values = [values] unless values.is_a?(Array)
        column = _schema[:columns][property]
        ranges = values.map { |value| column[:mapping][value] }.flatten
        ids = _intersect(ids, ranges)
      end
      Query.new(self, ids)
    end

    def self.all
      where
    end

    def self.count
      all.count
    end

    def self.last
      all.last
    end

    def self.each(&block)
      all.each(&block)
    end

    def self.pluck(*args)
      all.pluck(args)
    end

    def self.sample(limit=1)
      all.sample(limit)
    end

    def self.column(property, *args)
      args.each do |arg|
        index =
          case arg
          when Hash
            :distribution
          when Proc
            :generator
          else
            raise "bad argument"
          end
        _schema[:columns][property][index] = arg
      end
      define_method(property) do
        _generate_column(property)
      end
    end

    def self.rand(args)
      _db.prng.rand(args)
    end

    def self.value(id, property)
      return id if property == :id
      column = _schema[:columns][property]
      value =
        unless column[:mapping].nil?
          column[:mapping].find do |value, ranges|
            ranges.any? { |range| range.include?(id) }
          end&.first
        end
      unless column[:generator].nil?
        self._seed_prng(id, property)
        if value.nil?
          value = column[:generator].call(@id)
        else
          value = column[:generator].call(@id, value)
        end
      end
      value
    end

    private

    def self._intersect(ranges_1, ranges_2)
      retval = []
      ranges_1.each do |range_1|
        ranges_2.each do |range_2|
          retval << (range_1 & range_2)
        end
      end
      retval.compact
    end

    def self._db
      Thread.current[:rndb_database]
    end

    def self._migrate(size)
      raise "table already migrated" unless _schema[:class].nil?
      ranges = [Slice.new(0, size - 1)]
      _schema[:columns].each do |property, column|
        distribution = column[:distribution]
        next if distribution.nil?
        raise unless distribution.values.sum == 1
        ranges = _add_mapping(column, ranges)
      end
      _schema[:size] = size
      _schema[:class] = self
    end

    def self._schema
      Thread.current[:rndb_tables] ||= Hash.new do |tables, name|
        tables[name] = {
          class: nil,
          size: 0,
          columns: Hash.new do |columns, key|
            columns[key] = {
              distribution: nil,
              mapping: Hash.new do |distribution, value|
                distribution[value] = []
              end,
              generator: nil
            }
          end,
        }
      end
      Thread.current[:rndb_tables][table_name]
    end

    def self._add_mapping(column, ranges)
      ranges.each do |range|
        min = range.min
        flength = 0.0
        column[:distribution].each do |value, probability|
          flength += range.count * probability
          length = flength.round
          if length > 0
            column[:mapping][value] << Slice.new(min, min + length - 1)
            min += length
            flength -= length
          end
        end
        if flength > 0.01
          debugger
        end
      end
      ranges.clear
      column[:mapping].each do |value, distribution|
        ranges << distribution
      end
      ranges.flatten
    end

    def self._seed_prng(id, property)
      tuple = [_db.seed, table_name, property, id].join('-')
      digest = Digest::SHA256.hexdigest(tuple)
      value = digest.to_i(16) % 18446744073709551616
      _db.prng.srand(value)
      Faker::Config.random = _db.prng
      value
    end

    def _generate_all
      self.class._schema[:columns].keys.each do |name|
        _generate_column(name)
      end
      @_attributes
    end

    def _generate_column(name)
      @_attributes ||= { id: @id }
      @_attributes[name] ||= self.class.value(@id, name)
    end
  end
end
