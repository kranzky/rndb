# frozen_string_literal: true

module RnDB
  class Slice < Range
    # A range that knows how to sort and intersect itself.
    def initialize(min, max)
      super(min.to_i, max.to_i)
    end

    # Just in case the Range implementation is inefficient.
    def count
      max - min + 1
    end

    # Because Slices in a Thicket are disjoint, we can sort by min or max.
    def <=>(other)
      min <=> other.min
    end

    # We need to intersect slices when processing query constraints.
    def &(other)
      return nil if min > other.max || max < other.min
      self.class.new([min, other.min].max, [max, other.max].min)
    end

    # We don't need union yet, but it'd be useful for OR queries.
    def |(other)
      self.class.new([min, other.min].min, [max, other.max].max)
    end
  end
end
