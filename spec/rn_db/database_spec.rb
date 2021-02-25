# frozen_string_literal: true

describe RnDB::Database do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    described_class.new(137).add_table(Ball, 1_000_000)
  end

  it "can be counted" do
    expect(Ball.count).to eq(1_000_000)
  end

  it "has a first element" do
    expect(Ball.first.id).to eq(0)
  end

  it "has a last element" do
    expect(Ball.last.id).to eq(999_999)
  end

  it "can find things" do
    ball = Ball.find { |b| b.location =~ /island/i }
    expect(ball.location).to match(/Island/)
  end

  it "can take random samples" do
    ids = Ball.sample(10).pluck(:id)
    expect(ids.sort.uniq.size).to eq(10)
  end

  context "when running a query" do
    let(:query) do
      Ball.where(colour: [:red, :blue], material: :wood)
    end

    it "can be counted" do
      expect(query.count).to eq(240_000)
    end

    it "has a first element" do
      expect(query.first.id).to eq(5400)
    end

    it "has a last element" do
      expect(query.last.id).to eq(905_499)
    end

    it "can find things" do
      ball = query.find { |b| !b.transparent }
      expect(ball.transparent).to be(false)
    end

    it "can take random samples" do
      ids = query.sample(10).pluck(:id)
      expect(ids.sort.uniq.size).to eq(10)
    end
  end
end
