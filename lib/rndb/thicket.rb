# frozen_string_literal: true

module RnDB
  class Thicket
    include Enumerable

    # A sorted array of disjoint ranges, optionally initialised with a default range.
    def initialize(range=nil)
      @ids = []
      @ids << Slice.new(range.min, range.max) unless range.nil?
    end

    # Append a range, throwing an error if it overlaps with an existing range,
    # and keeping the resulting array sorted so we can iterate over values.
    def <<(range)
      slice = Slice.new(range.min, range.max)
      raise "slices in thicket must be disjoint" unless @ids.all? { |id| (id & slice).nil? }
      @ids << Slice.new(range.min, range.max)
      @ids.sort!
      self
    end

    # Intersect two Thickets, useful when performing queries.
    def &(other)
      retval = self.class.new
      slices.each do |slice|
        other.slices.each do |other_slice|
          next unless (intersection = slice & other_slice)
          retval << intersection
        end
      end
      retval
    end

    # Merge two Thickets, which we need during migrations.
    def |(other)
      retval = self.class.new
      slices.each { |slice| retval << slice }
      other.slices.each { |slice| retval << slice }
      retval
    end

    # Subdivide a Thicket with a probability range, also used for migrations.
    def *(other)
      slices.each_with_object(self.class.new) do |slice, thicket|
        min = slice.min + (slice.count * other.min).round
        max = slice.min + (slice.count * other.max).round - 1
        thicket << (min..max) unless max < min
      end
    end

    # Sum the counts of the Slices in the Thicket.
    def count
      @ids.map(&:count).sum
    end

    # Return the ID corresponding to the supplied index.
    def [](index)
      index += count while index.negative?
      @ids.each do |slice|
        return index + slice.min if index < slice.count
        index -= slice.count
      end
      nil
    end

    # Return the index corresponding to the supplied ID.
    def index(id)
      start = 0
      @ids.each do |slice|
        return start + id - slice.min if slice.include?(id)
        start += slice.count
      end
      nil
    end

    # Test whether the specified ID exists in this Thicket.
    def include?(id)
      @ids.any? { |slice| slice.include?(id) }
    end

    # Implemented to be consistent with #first, which we get by magic.
    def last
      self[-1] unless count.zero?
    end

    # Iterate over each slice in the Thicket in turn.
    def each(&block)
      @ids.each { |slice| slice.each(&block) }
    end

    # Return a Thicket that contains a sampling of IDs.
    def sample(limit=1, prng=Random)
      ids = Set.new
      limit = [limit, count].min
      ids << self[prng.rand(count)] while ids.count < limit
      ids.sort.each_with_object(self.class.new) do |id, thicket|
        thicket << Slice.new(id, id)
      end
    end

    # We display the internal slices.
    def to_s
      slices.to_s
    end

    alias min first
    alias max last

    protected

    def slices
      @ids
    end
  end
end
