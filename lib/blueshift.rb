require 'blueshift/railtie' if defined?(Rails)
require 'blueshift/version'
require 'logger'
require 'sequel'
require 'sequel/adapters/redshift'
require 'sequel/extensions/schema_dumper_ext'
require 'sequel/extensions/redshift_schema_dumper'

module Blueshift
  def self.redshift
    @redshift ||= Sequel.connect(ENV.fetch('REDSHIFT_URL', 'redshift://'), logger: Logger.new('redshift.log'))
  end

  def self.postgres
    @postgres ||= Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://'), logger: Logger.new('postgres.log'))
  end

  def self.connect
    if ENV['REDSHIFT_URL'].exists?
      redshift
    elsif ENV['DATABASE_URL'].exists?
      postgres
    end
  end
end
