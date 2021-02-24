# RnDB

RnDB is a procedurally-generated fake database.

## Usage

First, create tables with columns that may have a pre-determined distribution of
values (which can be queried on), or which may have a lambda for generating a
random value, or both (such as for the `weight` column below).

```
class Widget < RnDB::Table
  column :colour, { red: 0.3, green: 0.12, brown: 0.01, blue: 0.5, orange: 0.07 }
  column :weight, { light: 0.3, medium: 0.64, heavy: 0.06 }, -> value do
    range =
      case value
      when :light
        (0.0..5.0)
      when :medium
        (6.0..9.0)
      when :heavy
        (10.0..20.0)
      end
    self.rand(range)
  end
  column :name, -> { Faker::Games::Pokemon.name }
end
```

Next, create a database with an optional random seed (`137` in the example
below), and add the table to the database, specifying the number of records to
simulate (in this case, one trillion).

```
DB = RnDB::Database.new(137)
DB.add_table(Widget, 1e12)
```

Finally, query that thing!

```
> Widget.count
=> 1000000000000
> Widget[1234567890].name
=> "Charmander"
> Widget.find { |widget| (3.1415..3.1416).include?(widget.weight) }.attributes
{:id=>61520, :weight=>3.1415121332762386, :colour=>:red, :name=>"Exeggcute"}
> query = Widget.where(colour: [:brown, :orange], :weight => :heavy) ; query.count
=> 4800000000
> query.sample(2).pluck(:colour, :weight)
=> [{:colour=>:orange, :weight=>10.958051883041504}, {:colour=>:brown, :weight=>18.232519081499262}]
> query.lazy.filter { |ball| ball.name == 'Pikachu' }.map(&:id).take(10).to_a
=> [429400000142, 429400000371, 429400000426, 429400000679, 429400000838, 429400000945, 429400001026, 429400001191, 429400001339, 429400001625]
```

## Copyright

Copyright (c) 2021 Jason Hutchens. See LICENSE for further details.
