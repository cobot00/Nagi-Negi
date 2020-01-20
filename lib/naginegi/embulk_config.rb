module Naginegi
  class EmbulkConfig
    def generate_config(db_configs, bq_config)
      bq_utility = BigQuery.new(bq_config)

      db_configs.keys.each do |db_name|
        db_config = db_configs[db_name]
        table_configs = all_table_configs[db_name]
        db_type = db_config['db_type']

        case db_type
        when 'mysql'
          sql_client = MySQL::MySQLClient.new(db_config)
        when 'postgresql'
          sql_client = PostgreSQL::PgClient.new(db_config)
        end

        table_configs.each do |table_config|
          write(
            "#{bq_config['schema_dir']}/#{db_name}",
            "#{table_config.name}.json",
            sql_client.generate_bq_schema(table_config.name)
          )
          write(
            "#{bq_config['config_dir']}/#{db_name}",
            "#{table_config.name}.yml",
            bq_utility.generate_embulk_config(
              db_name,
              db_config,
              table_config,
              sql_client.columns(table_config.name)
            )
          )
        end
      end
    end

    private

    def write(directory, file_name, content)
      FileUtils.mkdir_p(directory) unless FileTest.exist?(directory)
      File.write("#{directory}/#{file_name}", content)
    end

    def all_table_configs
      @all_table_configs ||= Naginegi::TableConfig.generate_table_configs
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
      configs.each_with_object({}) do |(db, database_config), table_configs|
        table_configs[db] = database_config['tables'].map { |config| TableConfig.new(config) }
        table_configs
      end
    end

    def ==(other)
      instance_variables.all? do |v|
        instance_variable_get(v) == other.instance_variable_get(v)
      end
    end
  end
end
