# frozen_string_literal: true

require 'digest'
require 'byebug'

module RnDB
  class Table
    attr_reader :id

    # Create a new record wit the given ID.
    def initialize(id)
      _validate!
      @id = id
    end

    # Generate all attributes, which may be expensive.
    def attributes
      _generate_all
    end

    # Return the attributes as a hash.
    def to_h
      attributes
    end

    # Return a stringified version of the attributes hash.
    def to_s
      to_h.to_s
    end

    private

    def _generate_all
      _schema[:columns].each_key do |name|
        _generate_column(name)
      end
      @_attributes
    end

    def _generate_column(name)
      @_attributes ||= { id: @id }
      @_attributes[name] ||= self.class.value(@id, name)
    end

    def _validate!
      self.class.send(:_validate!)
    end

    def _schema
      self.class.send(:_schema)
    end

    class << self
      include Enumerable

      # Return the name of the table, which is derived from the class name.
      def table_name
        name.downcase.to_sym
      end

      # Return a new record corresponding to the specified index.
      def [](index)
        _validate!
        new(index) if index < count
      end

      # Return a Query that matches the supplied constraints
      def where(constraints={})
        _validate!
        ids = Thicket.new(0..._schema[:size])
        constraints.each do |attribute, values|
          column = _schema[:columns][attribute]
          other = Array(values).reduce(Thicket.new) do |thicket, value|
            column[:mapping][value].reduce(thicket) do |_, range|
              thicket << range
            end
          end
          ids &= other
        end
        Query.new(self, ids)
      end

      # Return all records.
      def all
        where
      end

      # Count all records, delegating this to the all Query.
      def count
        all.count
      end

      # Return the last record, to be consistent with #first, which we get by magic.
      def last
        all.last
      end

      # Iterate over all records, delegating this to the all Query
      def each(&block)
        all.each(&block)
      end

      # Pluck specified attributes from all records, delegating this to the all query.
      def pluck(*args)
        all.pluck(args)
      end

      # Return a Querty that contains a random sampling of records.
      def sample(limit=1)
        all.sample(limit)
      end

      # Add a new column to the Table model.
      def column(attribute, *args)
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
          _schema[:columns][attribute][index] = arg
        end
        define_method(attribute) do
          _generate_column(attribute)
        end
      end

      # Generate a random number, intended to be used in lambdas. The number
      # will have been seeded appropriately to ensure determinism.
      def rand(args)
        _validate!
        _db.prng.rand(args)
      end

      # Retrieve the value of the given attribute for the given ID.
      def value(id, attribute)
        _validate!
        return id if attribute == :id
        column = _schema[:columns][attribute]
        value =
          unless column[:distribution].nil?
            column[:mapping].find do |_, ranges|
              ranges.any? { |range| range.include?(id) }
            end&.first
          end
        unless column[:generator].nil?
          _seed_prng(id, attribute)
          value =
            if column[:distribution].nil?
              column[:generator].call
            else
              column[:generator].call(value)
            end
        end
        value
      end

      private

      def _db
        Thread.current[:rndb_database]
      end

      def _schema
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
            end
          }
        end
        Thread.current[:rndb_tables][table_name]
      end

      def _migrate(size)
        raise "table already migrated" unless _schema[:class].nil?
        # TODO: ranges = Thicket.new(0...size)
        # TODO: figure out an elegant implementation with thickets
        ranges = [Slice.new(0, size - 1)]
        _schema[:columns].each_value do |column|
          distribution = column[:distribution]
          next if distribution.nil?
          raise unless distribution.values.sum == 1
          ranges = _add_mapping(column, ranges)
        end
        _schema[:size] = size
        _schema[:class] = self
      end
      def _add_mapping(column, ranges)
        ranges.each do |range|
          min = range.min
          flength = 0.0
          column[:distribution].each do |value, probability|
            flength += range.count * probability
            length = flength.round
            next if length.zero?
            column[:mapping][value] << Slice.new(min, min + length - 1)
            min += length
            flength -= length
          end
        end
        ranges.clear
        column[:mapping].each_value do |distribution|
          ranges << distribution
        end
        ranges.flatten
      end

      def _seed_prng(id, attribute)
        tuple = [_db.seed, table_name, attribute, id].join('-')
        digest = Digest::SHA256.hexdigest(tuple)
        value = digest.to_i(16) % 18_446_744_073_709_551_616
        _db.prng.srand(value)
        Faker::Config.random = _db.prng
        value
      end

      def _validate!
        @valid ||= (self == _schema[:class])
        raise "table not added to database" unless @valid
      end
    end
  end
end
