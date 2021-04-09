Bundler.require(:test)
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dotenv'
Dotenv.load

Dir.chdir('spec/support') do
  require 'blueshift'
end

DB = Sequel.connect(ENV['REDSHIFT_URL'] || 'redshift://localhost/db', logger: Logger.new('test.log'))
PGDB = Sequel.connect(ENV['DATABASE_URL'] || 'postgresql://localhost/db', logger: Logger.new('test.log'))

RSpec.configure do |config|
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end

