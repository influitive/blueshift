require 'spec_helper'

RSpec.describe Sequel::Redshift do
  it { is_expected.to include Sequel::Postgres }

  it { expect(DB.supports_index_parsing?).to eq false }

  describe '#create_table' do
    describe 'sortkeys' do
      let(:sql) { 'CREATE TABLE "foos" () SORTKEY (hello)' }

      it 'accepts a :sortkeys option' do
        expect(DB).to receive(:execute_ddl).with(sql)

        DB.create_table :foos, sortkeys: :hello
      end
    end

    it 'accepts multiple sortkeys' do
      sql = 'CREATE TABLE "foos" () SORTKEY (hello, world)'
      expect(DB).to receive(:execute_ddl).with(sql)

      DB.create_table :foos, sortkeys: [:hello, :world]
    end

    describe 'sortstyle' do
      it 'accepts a sortstyle option with sortkeys' do
        sql = 'CREATE TABLE "foos" () INTERLEAVED SORTKEY (hello)'
        expect(DB).to receive(:execute_ddl).with(sql)
        DB.create_table :foos, sortkeys: :hello, sortstyle: :interleaved
      end

      it 'accepts a compound sortstyle' do
        sql = 'CREATE TABLE "foos" () COMPOUND SORTKEY (hello)'
        expect(DB).to receive(:execute_ddl).with(sql)
        DB.create_table :foos, sortkeys: :hello, sortstyle: :compound
      end

      it 'does not accept other sortstyles' do
        expect { DB.create_table :foos, sortkeys: :hello, sortstyle: :other }.to raise_error(ArgumentError, 'sortstyle must be one of :compound or :interleaved')
      end
    end

    describe 'distkey' do
      it 'accepts a distkey option' do
        sql = 'CREATE TABLE "chocolates" ("region" varchar(255), "richness" integer) DISTKEY (region)'
        expect(DB).to receive(:execute_ddl).with(sql)

        DB.create_table :chocolates, distkey: :region do
          varchar :region
          Integer :richness
        end
      end
    end

    describe 'diststyle' do
      it 'allows you to change the diststyle' do
        sql = 'CREATE TABLE "chocolates" ("region" varchar(255), "richness" integer) DISTSTYLE ALL'
        expect(DB).to receive(:execute_ddl).with(sql)

        DB.create_table :chocolates, diststyle: :all do
          varchar :region
          Integer :richness
        end
      end

      it 'allows EVEN distribution style' do
        sql = 'CREATE TABLE "chocolates" ("region" varchar(255), "richness" integer) DISTSTYLE EVEN'
        expect(DB).to receive(:execute_ddl).with(sql)

        DB.create_table :chocolates, diststyle: :even do
          varchar :region
          Integer :richness
        end
      end

      it 'does not accept invalid distkeys' do
        expect { DB.create_table :monkeys, diststyle: :bananas }.to raise_error(ArgumentError, 'diststyle must be one of :even, key, or :all')
      end

      describe 'column types' do
        describe 'string uuid' do
          it 'supports fixed-width string uuid columns' do
            sql = 'CREATE TABLE "chocolates" ("id" char(36))'
            expect(DB).to receive(:execute_ddl).with(sql)

            DB.create_table :chocolates do
              Suuid :id
            end
          end

          it 'supports fixed-width string uuid columns that can be not nullable' do
            sql = 'CREATE TABLE "chocolates" ("id" char(36) NOT NULL)'
            expect(DB).to receive(:execute_ddl).with(sql)

            DB.create_table :chocolates do
              Suuid :id, null: false
            end
          end
        end

        describe 'string' do
          it 'uses varchar instead of text column type' do
            sql = 'CREATE TABLE "chocolates" ("name" varchar(255))'
            expect(DB).to receive(:execute_ddl).with(sql)

            DB.create_table :chocolates do
               String :name
            end
          end
        end
      end
    end
  end

  describe '#optimize_table' do
    before do
      DB.create_table! :characters do
        String :name
        String :ability
        Fixnum :age
        String :accent
      end
    end
  end
end
