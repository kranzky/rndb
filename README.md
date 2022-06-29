[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![test](https://github.com/kranzky/rndb/actions/workflows/test.yml/badge.svg)](https://github.com/kranzky/rndb/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/kranzky/rndb/badge.svg?branch=main)](https://coveralls.io/github/kranzky/rndb?branch=main)
[![Gem Version](https://badge.fury.io/rb/rndb.svg)](https://badge.fury.io/rb/rndb)
[![Western Australia](https://corona.kranzky.com/oc/anz/au/wa/badge.svg)](https://corona.kranzky.com?region=oc&subregion=anz&country=au&state=wa)

# RnDB

RnDB is a procedurally-generated fake database. Read the [blog post](https://medium.com/the-magic-pantry/the-case-of-the-fake-database-7bde487213a3) for details.

## Video Overview

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/hbn5J4yRrJ8/0.jpg)](https://www.youtube.com/watch?v=hbn5J4yRrJ8)

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

Finally, fetch some records!

```
puts Widget.count
puts Widget[1234567890].name
puts Widget.find { |widget| (3.1415..3.1416).include?(widget.weight) }.attributes
```

Which will display the following:

```
1000000000000
Charmander
{:id=>61520, :weight=>3.1415121332762386, :colour=>:red, :name=>"Exeggcute"}
```

Note that the `find` command tested over sixty thousand records in just a second
or two without needing to generate all attributes of each record first. But an
even faster way of honing in on a particular record is to run a query, such as:

```
query = Widget.where(colour: [:brown, :orange], :weight => :heavy)
```

You can then retrieve random records that match the query with `sample`, use
`pluck` to retrieve specific attributes without generating all of them, and use
`find` or `filter` to further refine your search, like this:

```
puts query.count
puts query.sample.pluck(:colour, :weight)
puts query.lazy.filter { |ball| ball.name == 'Pikachu' }.map(&:id).take(10).to_a
```

Which will display the following:

```
4800000000
{:colour=>:orange, :weight=>16.096085279047017}
[429400000068, 429400000087, 429400000875, 429400000885, 429400000914, 429400001036, 429400001062, 429400001330, 429400001341, 429400001438]
```

Note that we used the `lazy` enumerator when filtering records to prevent
running the block on all records before performing the `map` and taking the
first ten results.

## Release Process

1. `rake standard:fix`
2. `rake version:bump:whatever`
3. `rake gemspec:release BRANCH=main`
4. `rake git:release BRANCH=main`
5. Create new release on GitHub to trigger ship workflow

## Copyright

Copyright (c) 2021 Jason Hutchens. See LICENSE for further details.
