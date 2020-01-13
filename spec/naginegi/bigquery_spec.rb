require 'spec_helper'
require 'unindent'
require 'timecop'

RSpec.describe Naginegi::BigQuery do
  describe '.generate_schema' do
    subject { Naginegi::BigQuery.generate_schema(columns) }

    let(:columns) do
      [
        Naginegi::MySQL::Column.new('id', 'int'),
        Naginegi::MySQL::Column.new('name', 'varchar'),
        Naginegi::MySQL::Column.new('created_at', 'datetime')
      ]
    end

    let(:schema_json) do
      <<-JSON.unindent
      [
      {"name":"id","type":"INT64"},
      {"name":"name","type":"STRING"},
      {"name":"created_at","type":"TIMESTAMP"}
      ]
      JSON
    end

    it { expect(subject).to eq schema_json }
  end

  describe '.generate_sql' do
    subject { Naginegi::BigQuery.generate_sql(table_config, columns) }

    let(:columns) do
      [
        Naginegi::MySQL::Column.new('id', 'int'),
        Naginegi::MySQL::Column.new('name', 'varchar'),
        Naginegi::MySQL::Column.new('created_at', 'datetime')
      ]
    end

    context 'no condition' do
      let(:table_config) { Naginegi::MySQL::TableConfig.new({ 'name' => 'simple' }) }
      let(:sql) { "SELECT `id`,`name`,UNIX_TIMESTAMP(`created_at`) AS `created_at` FROM simple\n" }
      it { expect(subject).to eq sql }
    end

    context 'has condition' do
      let(:table_config) { Naginegi::MySQL::TableConfig.new({ 'name' => 'simple', 'condition' => 'created_at >= CURRENT_DATE() - INTERVAL 3 MONTH' }) }
      let(:sql) { "SELECT `id`,`name`,UNIX_TIMESTAMP(`created_at`) AS `created_at` FROM simple WHERE created_at >= CURRENT_DATE() - INTERVAL 3 MONTH\n" }
      it { expect(subject).to eq sql }
    end
  end

  describe '#actual_table_name' do
    before { Timecop.freeze(Time.now) }

    after { Timecop.return }

    subject { Naginegi::BigQuery.new({}).actual_table_name(table_name, daily_snapshot) }
    let(:table_name) { 'users' }
    let(:daily_snapshot) { false }

    context 'do not use daily snapshot' do
      it { expect(subject).to eq table_name }
    end

    context 'use daily snapshot' do
      let(:daily_snapshot) { true }
      it { expect(subject).to eq table_name + Time.now.strftime('%Y%m%d') }
    end
  end

  describe '#actual_table_name' do
    before { Timecop.freeze(Time.now) }

    after { Timecop.return }

    subject { Naginegi::BigQuery.new({}).actual_table_name(table_name, daily_snapshot) }
    let(:table_name) { 'users' }
    let(:daily_snapshot) { false }

    context 'do not use daily snapshot' do
      it { expect(subject).to eq table_name }
    end

    context 'use daily snapshot' do
      let(:daily_snapshot) { true }
      it { expect(subject).to eq table_name + Time.now.strftime('%Y%m%d') }
    end
  end
end
