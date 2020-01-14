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
      @all_table_configs ||= MySQL::TableConfig.generate_table_configs
    end
  end
end
