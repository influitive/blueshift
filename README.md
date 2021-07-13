# Blueshift


The Amazon Redshift adapter for Sequel

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blue-shift'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blue-shift

## Usage

[`create_table`](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html#method-i-create_table) Options:

- `:distkey` => column name

    The Distribution Key. When specified, the :diststyle is set to :key unless otherwise specified

- `:diststyle` => `:even` (implicit default), `:key`, or `:all`

    The Distribution Style. When `:distkey` is also specified, only `:key` DISTSTYLE is supported by Redshift and will be ignored by Postgres

- `:sortkeys` => a list of column names

    The Sort Keys. Depending on your `:sortstyle`, there is a maximum number of sortkeys that you can specify:
      Compound: up to 400 sortkeys
      Interleaved: up to 8 sortkeys
    
- `:sortstyle` => `:compound` (default) or `:interleaved`

    The Sort Style. This option has no effect unless `:sortkeys` is also specified
        
For example:

```ruby
create_table :chocolates, distkey: :region, diststyle: :key, sortkeys: [:richness, :organic], sortstyle: :interleaved do
    String  :region
    Integer :richness
    boolean :organic
    String  :description
end
```

You can also redeclare the sortkeys for an existing table by using the `optimize_table` method. This is reconstructive, no additive. For example:

```ruby
optimize_table :chocolates, sortkeys: [:organic, :region], distkey: :region 
```


### Migrations

Blueshift unifies migrations for your Postgres and Redshift databases into one file. Postgres migrations and Redshift migrations use Sequel.

```ruby
Blueshift.migration do
  up do
    # applies to Postgres only
  end

  down do
    # applies to Postgres only
  end
  
  redup do
    # applies to Redshift only
  end
  
  reddown do
    # applies to Redshift only
  end
end
```

If you want your migration to only run on Postgres, you can specify an empty block:

```ruby
Blueshift.migration do
  up do
    # applies to Postgres only
  end

  down do
    # applies to Postgres only
  end
  
  redup {}
  
  reddown {}
end
```

#### Transactions

By default, each migration runs within a transaction.
You can manually specify to disable transactions on a per migration basis. For example, if you want to not force
transaction use for a particular migration, call the `no_transaction` method in the `Blueshift.migration` block:

```ruby
Blueshift.migration do
  no_transaction
  up do
    # ...
  end
end
```

This is necessary in some cases, such as when attempting to use `CREATE INDEX CONCURRENTLY`
on PostgreSQL (which supports transactional schema, but not that statement inside a transaction).

Also, because each `optimize_table` call gets run within its own transaction, you should probably
use no_transaction in migrations that use that in order to prevent starting multiple transactions
within one another.
       
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/influitive/blueshift.

