require 'blueshift/railtie' if defined?(Rails)
require 'blueshift/version'
require 'logger'
require 'sequel'
require 'sequel/adapters/redshift'
require 'sequel/extensions/schema_dumper_ext'
require 'sequel/extensions/redshift_schema_dumper'

module Blueshift
end
