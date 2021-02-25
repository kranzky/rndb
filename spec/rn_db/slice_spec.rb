# frozen_string_literal: true

describe RnDB::Slice do
  it "has a count" do
    slice = described_class.new(5, 13)
    expect(slice.count).to eq(slice.to_a.length)
  end

  it "can find the intersection of two slices" do
    left = described_class.new(5, 13)
    right = described_class.new(10, 17)
    expect(left & right).to eq(described_class.new(10, 13))
  end

  it "returns nil if the intersection is empty" do
    left = described_class.new(5, 10)
    right = described_class.new(12, 17)
    expect(left & right).to be_nil
  end

  it "can find the union of two slices" do
    left = described_class.new(5, 13)
    right = described_class.new(10, 17)
    expect(left | right).to eq(described_class.new(5, 17))
  end
end
