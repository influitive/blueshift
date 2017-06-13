require 'sequel/adapters/postgres_ext'

module Sequel
  module Redshift
    include Postgres

    class Database < Postgres::Database
      set_adapter_scheme :redshift
      SORTSTYLES = [:compound, :interleaved].freeze
      DISTSTYLES = [:even, :key, :all].freeze

      def optimize_table(table, create_options)
        extension :redshift_schema_dumper
        transaction do
          gen = dump_table_generator(table)

          rename_table table, :"old_#{table}"
          create_table(:"new_#{table}", create_options) do
            instance_eval(gen.dump_columns,     __FILE__, __LINE__)
            instance_eval(gen.dump_constraints, __FILE__, __LINE__)
            instance_eval(gen.dump_indexes,     __FILE__, __LINE__)
          end
          run %Q{INSERT INTO "new_#{table}" (SELECT * FROM "old_#{table}")}
          rename_table :"new_#{table}", table
          drop_table :"old_#{table}"
        end
      end

      def serial_primary_key_options
        # redshift doesn't support serial type
        super.merge(serial: false)
      end

      def connection_configuration_sqls
        []
      end

      def supports_index_parsing?
        false
      end

      private

      def type_literal_generic_string(column)
        super(column.merge(text: false))
      end

      def create_table_sql(name, generator, options)
        validate_options!(options)
        sql = super
        sql += diststyle_sql(options)
        sql += distkey_sql(options)
        sql += sortstyle_sql(options)

        sql
      end

      def diststyle_sql(options)
        if options[:diststyle]
          " DISTSTYLE #{options[:diststyle].to_s.upcase}"
        end.to_s
      end

      def distkey_sql(options)
        if options[:distkey]
          " DISTKEY (#{options[:distkey]})"
        end.to_s
      end

      def sortstyle_sql(options)
        if options[:sortkeys]
          style = options[:sortstyle].to_s.upcase
          " #{style} SORTKEY (#{Array(options[:sortkeys]).join(', ')})".squeeze(' ')
        end.to_s
      end

      def validate_options!(options)
        raise ArgumentError, 'sortstyle must be one of :compound or :interleaved' if invalid?(options[:sortstyle], SORTSTYLES)
        raise ArgumentError, 'diststyle must be one of :even, key, or :all' if invalid?(options[:diststyle], DISTSTYLES)
      end

      def invalid?(value, allowed)
        value && !allowed.include?(value)
      end

      # OVERRIDE for Redshift. Now always expect the "id" column to be the primary key
      # The dataset used for parsing table schemas, using the pg_* system catalogs.
      def schema_parse_table(table_name, opts)
        m = output_identifier_meth(opts[:dataset])
        ds = metadata_dataset.select(:pg_attribute__attname___name,
            SQL::Cast.new(:pg_attribute__atttypid, :integer).as(:oid),
            SQL::Cast.new(:basetype__oid, :integer).as(:base_oid),
            SQL::Function.new(:format_type, :basetype__oid, :pg_type__typtypmod).as(:db_base_type),
            SQL::Function.new(:format_type, :pg_type__oid, :pg_attribute__atttypmod).as(:db_type),
            SQL::Function.new(:pg_get_expr, :pg_attrdef__adbin, :pg_class__oid).as(:default),
            SQL::BooleanExpression.new(:NOT, :pg_attribute__attnotnull).as(:allow_null),
            SQL::Function.new(:COALESCE, SQL::BooleanExpression.from_value_pairs(:pg_attribute__attnum => SQL::Function.new(:ANY,
              SQL::Function.new(:string_to_array, SQL::Function.new(:textin, SQL::Function.new(:int2vectorout, :pg_index__indkey)), ' ')
            )), false).as(:primary_key)).
          from(:pg_class).
          join(:pg_attribute, :attrelid=>:oid).
          join(:pg_type, :oid=>:atttypid).
          left_outer_join(:pg_type___basetype, :oid=>:typbasetype).
          left_outer_join(:pg_attrdef, :adrelid=>:pg_class__oid, :adnum=>:pg_attribute__attnum).
          left_outer_join(:pg_index, :indrelid=>:pg_class__oid, :indisprimary=>true).
          filter(:pg_attribute__attisdropped=>false).
          filter{|o| o.pg_attribute__attnum > 0}.
          filter(:pg_class__oid=>regclass_oid(table_name, opts)).
          order(:pg_attribute__attnum)
        ds.map do |row|
          row[:default] = nil if blank_object?(row[:default])
          if row[:base_oid]
            row[:domain_oid] = row[:oid]
            row[:oid] = row.delete(:base_oid)
            row[:db_domain_type] = row[:db_type]
            row[:db_type] = row.delete(:db_base_type)
          else
            row.delete(:base_oid)
            row.delete(:db_base_type)
          end
          row[:type] = schema_column_type(row[:db_type])
          if row[:primary_key]
            row[:auto_increment] = !!(row[:default] =~ /\Anextval/io)
          end
          [m.call(row.delete(:name)), row]
        end
      end

      def dataset_class_default
        Dataset
      end
    end

    class Dataset < Postgres::Dataset
      # Redshift doesn't support RETURNING statement
      def insert_returning_sql(sql)
        # do nothing here
        sql
      end
    end
  end
end
