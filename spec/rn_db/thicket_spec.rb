# frozen_string_literal: true

describe RnDB::Thicket do
  it "is empty by default" do
    thicket = described_class.new
    expect(thicket.count).to be_zero
  end

  it "can be initialized with a value" do
    thicket = described_class.new(2, 21)
    expect(thicket.count).to eq((2..21).size)
  end

  it "can contain multiple disjoint slices" do
    thicket = described_class.new
    thicket << (11..16)
    thicket << (4..9)
    expect(thicket.to_a).to eq((4..9).to_a | (11..16).to_a)
  end

  it "can contain large values" do
    thicket = described_class.new(7, 1e15)
    expect((thicket.min..thicket.max)).to eq((7..1e15.to_i))
  end

  it "can return the id by index" do
    thicket = described_class.new
    thicket << (11..16)
    thicket << (4..9)
    expect(thicket[7]).to eq(12)
  end

  it "returns a nil value when the index is out of range" do
    thicket = described_class.new
    thicket << (11..16)
    thicket << (4..9)
    expect(thicket[16]).to be_nil
  end

  it "can get the index of an id" do
    thicket = described_class.new
    thicket << (11..16)
    thicket << (4..9)
    expect(thicket.index(12)).to eq(7)
  end

  it "returns a nil index when the id does not exist" do
    thicket = described_class.new
    thicket << (11..16)
    thicket << (4..9)
    expect(thicket.index(10)).to be_nil
  end
end
