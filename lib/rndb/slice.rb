# frozen_string_literal: true

module RnDB
  class Slice < Range
    def count
      max - min + 1
    end

    def &(other)
      return nil if min > other.max || max < other.min
      self.class.new([min, other.min].max, [max, other.max].min)
    end

    def |(other)
      self.class.new([min, other.min].min, [max, other.max].max)
    end
  end
end
