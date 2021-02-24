require 'faker'

class Ball < RnDB::Table
  column :colour, {
    red: 0.3,
    green: 0.1,
    brown: 0.01,
    blue: 0.5,
    orange: 0.09
  }
  column :transparent, {
    true => 0.1,
    false => 0.9
  }
  column :weight, {
    light: 0.3,
    medium: 0.6,
    heavy: 0.1
  }, -> value do
    puts "x"
    range =
      case value
      when :light
        (0.1..3.0)
      when :medium
        (3.0..6.0)
      when :heavy
        (6.0..9.9)
      end
    self.rand(range)
  end
  column :material, {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
  column :name, -> { Faker::Games::Pokemon.name }
  column :location, -> { Faker::Games::Pokemon.location }
  column :move, -> { Faker::Games::Pokemon.move }
end

describe RnDB do
  before(:all) do
    DB = RnDB::Database.new(137)
    DB.add_table(Ball, 1_000_000)
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
    ball = Ball.find { |ball| ball.location =~ /island/i }
    expect(ball.location).to match(/Island/)
  end

  it "can take random samples" do
    ids = Ball.sample(10).pluck(:id)
    expect(ids.sort.uniq.size).to eq(10)
  end

  it "can filter things" do
    moves = Ball.lazy.filter { |ball| ball.move =~ /fire/i }.take(10).map(&:move)
    expect(moves.all? { |move| move =~ /Fire/ }).to be(true)
  end

  context "for a query" do
    let(:query) do
      Ball.where(:colour => [:red, :blue], :material => :wood)
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
      ball = query.find { |ball| !ball.transparent }
      expect(ball.transparent).to be(false)
    end

    it "can take random samples" do
      ids = query.sample(10).pluck(:id)
      expect(ids.sort.uniq.size).to eq(10)
    end

    it "can filter things" do
      moves = query.lazy.filter { |ball| ball.move =~ /fire/i }.take(10).map(&:move)
      expect(moves.all? { |move| move =~ /Fire/ }).to be(true)
    end
  end
end
