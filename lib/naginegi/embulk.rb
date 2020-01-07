require 'logger'

module Naginegi
  class Embulk
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    end

    def run(database_configs, all_table_configs, bq_config, target_table_names = [])
      error_tables = []
      database_configs.keys.each do |db_name|
        table_configs = target_table_configs(all_table_configs[db_name], target_table_names)
        error_tables += run_by_database(
          db_name,
          table_configs,
          bq_config
        )
      end
      error_tables
    end

    def target_table_configs(table_configs, target_table_names)
      return table_configs if target_table_names.empty?
      table_configs.select { |table_config| target_table_names.include?(table_config.name) }
    end

    private

    def run_by_database(db_name, table_configs, bq_config)
      process_times = []
      error_tables = []

      table_configs.each do |table_config|
        start_time = Time.now
        @logger.info("table: #{table_config.name} - start")

        cmd = "embulk run #{bq_config['config_dir']}/#{db_name}/#{table_config.name}.yml"
        @logger.info("cmd: #{cmd}")

        if system(cmd)
          result = 'success'
        else
          result = 'error'
          error_tables << table_config.name
        end

        process_time = "table: #{table_config.name} - result: #{result}  #{format('%10.1f', Time.now - start_time)}sec"
        @logger.info(process_time)

        process_times << process_time
      end

      @logger.info('------------------------------------')
      @logger.info("db_name: #{db_name}")

      process_times.each { |process_time| @logger.info(process_time) }

      error_tables
    end
  end
end
