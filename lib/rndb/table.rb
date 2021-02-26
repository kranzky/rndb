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
      _schema[:columns].each do |name, column|
        _generate_column_key(name) if column[:generator] && column[:distribution]
        _generate_column(name)
      end
      _schema[:associations].each_key do |name|
        _generate_association_id(name)
      end
      @_attributes
    end

    def _generate_column_key(name)
      @_attributes ||= { id: @id }
      @_attributes["#{name}_key".to_sym] ||= self.class.key(@id, name)
    end

    def _generate_column(name)
      @_attributes ||= { id: @id }
      @_attributes[name] ||= self.class.value(@id, name)
    end

    def _generate_association_id(name)
      @_attributes ||= { id: @id }
      @_attributes["#{name}_id".to_sym] ||= _generate_association(name)&.id
    end

    def _generate_association(name)
      self.class.join(@id, name)
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
        Query.new(self, _query(constraints, _schema[:size]))
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
        column = _schema[:columns][attribute]
        args.each do |arg|
          index =
            case arg
            when Hash, Array
              :distribution
            when Proc
              :generator
            else
              raise "unsupported column parameter"
            end
          column[index] = arg
        end
        if column[:generator] && column[:distribution]
          define_method("#{attribute}_key") do
            _generate_column_key(attribute)
          end
        end
        define_method(attribute) do
          _generate_column(attribute)
        end
      end

      # Add an association between two Table models.
      def association(attribute, *args)
        args.each do |arg|
          _schema[:associations][attribute] = arg
        end
        define_method("#{attribute}_id".to_sym) do
          _generate_association_id(attribute)
        end
        define_method(attribute) do
          _generate_association(attribute)
        end
      end

      # Generate a random number, intended to be used in lambdas. The number
      # will have been seeded appropriately to ensure determinism.
      def rand(*args)
        _validate!
        _db.prng.rand(*args)
      end

      # Retrieve the key that can be queried on for generated attributes.
      def key(id, attribute)
        @current = id
        _validate!
        column = _schema[:columns][attribute]
        return if column[:distribution].nil?
        column[:mapping].find do |_, ids|
          ids.include?(id)
        end&.first
      end

      # Retrieve the value of the given attribute for the given ID.
      def value(id, attribute)
        @current = id
        _validate!
        return id if attribute == :id
        column = _schema[:columns][attribute]
        value = key(id, attribute)
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

      # Return the instance joined to the current ID.
      def join(id, name)
        @current = id
        _schema[:associations][name].each do |context|
          next unless (index = where(context[:where]).index(id))
          return where(context[:joins])[index]
        end
        nil
      end

      def get(attribute)
        raise unless @current
        if _schema[:columns].key?(attribute)
          value(@current, attribute)
        elsif _schema[:associations].key?(attribute)
          join(@current, attribute)
        else
          raise "no such attribute"
        end
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
                mapping: {},
                generator: nil
              }
            end,
            associations: Hash.new do |associations, key|
              associations[key] = nil
            end
          }
        end
        Thread.current[:rndb_tables][table_name]
      end

      def _query(constraints, size)
        ids = Thicket.new(0...size)
        constraints.each do |attribute, values|
          column = _schema[:columns][attribute]
          raise "no mapping for column" if column[:mapping].empty?
          other = Array(values).reduce(Thicket.new) do |thicket, value|
            thicket | column[:mapping][value]
          end
          ids &= other
        end
        ids
      end

      def _migrate_column(column, ids, distribution)
        min = 0.0
        distribution.each do |value, probability|
          max = min + probability
          column[:mapping][value] ||= Thicket.new
          column[:mapping][value] |= ids * (min..max)
          min = max
        end
      end

      def _migrate(size)
        raise "table already migrated" unless _schema[:class].nil?
        ids = Thicket.new(0...size)
        _schema[:columns].each_value do |column|
          distribution = column[:distribution]
          next if distribution.nil?
          if distribution.is_a?(Array)
            distribution.each do |context|
              thicket = ids & _query(context[:where], size)
              _migrate_column(column, thicket, context[:stats])
            end
          else
            raise "distribution must sum to unity" unless distribution.values.sum == 1
            _migrate_column(column, ids, distribution)
          end
          ids =
            column[:mapping].values.reduce(Thicket.new) do |thicket, other|
              thicket | other
            end
        end
        _schema[:size] = size
        _schema[:class] = self
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
