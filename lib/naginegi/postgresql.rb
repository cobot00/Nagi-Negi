require 'pg'
require 'json'
require 'yaml'
require 'fileutils'
require 'naginegi/bigquery'

module Naginegi
  module PostgreSQL
    class PgClient
      COLUMN_SQL = <<-SQL.freeze
        SELECT column_name, data_type
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE table_name = $1
        ORDER BY ordinal_position
      SQL

      def initialize(db_config)
        @db_config = db_config
      end

      def client
        @client ||= PG::Connection.new(
          host: @db_config['host'],
          user: @db_config['username'],
          password: @db_config['password'],
          dbname: @db_config['database']
        )
      end

      def generate_bq_schema(table_name)
        infos = columns(table_name)
        BigQuery.generate_schema(infos)
      end

      def columns(table_name)
        rows = client.exec_params(COLUMN_SQL, [table_name])
        rows.map { |row| Column.new(row['column_name'], row['data_type']) }
      end
    end

    class TableConfig
      attr_reader :name, :daily_snapshot, :condition

      def initialize(config)
        @name = config['name']
        @daily_snapshot = config['daily_snapshot'] || false
        @condition = config['condition']
      end

      def self.generate_table_configs(file_path = 'table.yml')
        configs = YAML.load_file(file_path)
        configs.each_with_object({}) do |(db, db_config), table_configs|
          table_configs[db] = db_config['tables'].map { |config| TableConfig.new(config) }
          table_configs
        end
      end

      def ==(other)
        instance_variables.all? do |v|
          instance_variable_get(v) == other.instance_variable_get(v)
        end
      end
    end

    class Column
      attr_reader :column_name, :data_type

      TYPE_MAPPINGS = {
        'smallint' => 'INT64',
        'integer' => 'INT64',
        'bigint' => 'INT64',
        'smallserial' => 'INT64',
        'serial' => 'INT64',
        'bigserial' => 'INT64',
        'decimal' => 'FLOAT64',
        'numeric' => 'FLOAT64',
        'real' => 'FLOAT64',
        'double precision' => 'FLOAT64',
        'character' => 'STRING',
        'character varying' => 'STRING',
        'text' => 'STRING',
        'date' => 'TIMESTAMP',
        'timestamp' => 'TIMESTAMP',
        'timestamp with time zone' => 'TIMESTAMP',
        'boolean' => 'BOOL'
      }.freeze

      def initialize(column_name, data_type)
        @column_name = column_name
        @data_type = data_type
      end

      def bigquery_data_type
        TYPE_MAPPINGS[@data_type]
      end

      def converted_value
        if bigquery_data_type == 'TIMESTAMP'
          # time zone translate to UTC
          "EXTRACT(EPOCH FROM #{escaped_column_name}) AS #{escaped_column_name}"
        else
          escaped_column_name
        end
      end

      def to_json(*a)
        { 'name' => @column_name, 'type' => bigquery_data_type }.to_json(*a)
      end

      private

      def escaped_column_name
        "\"#{@column_name}\""
      end
    end
  end
end
