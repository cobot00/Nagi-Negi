require 'mysql2-cs-bind'
require 'json'
require 'yaml'
require 'fileutils'
require 'naginegi/bigquery'

module Naginegi
  module MySQL
    class MySQLClient
      COLUMN_SQL = <<-SQL.freeze
        SELECT column_name, data_type
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE table_schema = ?
        AND table_name = ?
        ORDER BY ordinal_position
      SQL

      def initialize(database_config)
        @database_config = database_config
      end

      def client
        @client ||= Mysql2::Client.new(
          host: @database_config['host'],
          username: @database_config['username'],
          password: @database_config['password'],
          database: @database_config['database']
        )
      end

      def generate_bq_schema(table_name)
        infos = columns(table_name)
        BigQuery.generate_schema(infos)
      end

      def columns(table_name)
        rows = client.xquery(COLUMN_SQL, @database_config['database'], table_name)
        rows.map { |row| Column.new(row['column_name'], row['data_type']) }
      end
    end

    class Column
      attr_reader :column_name, :data_type

      TYPE_MAPPINGS = {
        'int' => 'INT64',
        'tinyint' => 'INT64',
        'smallint' => 'INT64',
        'mediumint' => 'INT64',
        'bigint' => 'INT64',
        'float' => 'FLOAT64',
        'double' => 'FLOAT64',
        'decimal' => 'FLOAT64',
        'char' => 'STRING',
        'varchar' => 'STRING',
        'tinytext' => 'STRING',
        'text' => 'STRING',
        'date' => 'TIMESTAMP',
        'datetime' => 'TIMESTAMP',
        'timestamp' => 'TIMESTAMP'
      }.freeze

      def initialize(column_name, data_type)
        @column_name = column_name
        @data_type = data_type
      end

      def bigquery_data_type
        TYPE_MAPPINGS[@data_type] || 'STRING'
      end

      def converted_value
        if bigquery_data_type == 'TIMESTAMP'
          # time zone translate to UTC
          "UNIX_TIMESTAMP(#{escaped_column_name}) AS #{escaped_column_name}"
        elsif data_type == 'tinyint'
          # for MySQL tinyint(1) problem
          "CAST(#{escaped_column_name} AS signed) AS #{escaped_column_name}"
        else
          escaped_column_name
        end
      end

      def to_json(*a)
        { 'name' => @column_name, 'type' => bigquery_data_type }.to_json(*a)
      end

      private

      def escaped_column_name
        "`#{@column_name}`"
      end
    end
  end
end
