require 'spec_helper'

RSpec.describe Naginegi::PostgreSQL::Column do
  let(:column) { Naginegi::PostgreSQL::Column.new(column_name, data_type) }
  let(:column_name) { 'id' }
  let(:data_type) { 'integer' }

  it { expect(column.column_name).to eq 'id' }
  it { expect(column.data_type).to eq 'integer' }

  describe '#bigquery_data_type' do
    subject { column.bigquery_data_type }

    context 'smallint' do
      let(:data_type) { 'smallint' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'integer' do
      let(:data_type) { 'integer' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'bigint' do
      let(:data_type) { 'bigint' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'smallserial' do
      let(:data_type) { 'smallserial' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'serial' do
      let(:data_type) { 'serial' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'bigserial' do
      let(:data_type) { 'bigserial' }
      it { expect(subject).to eq 'INT64' }
    end

    context 'decimal' do
      let(:data_type) { 'decimal' }
      it { expect(subject).to eq 'FLOAT64' }
    end

    context 'numeric' do
      let(:data_type) { 'numeric' }
      it { expect(subject).to eq 'FLOAT64' }
    end

    context 'real' do
      let(:data_type) { 'real' }
      it { expect(subject).to eq 'FLOAT64' }
    end

    context 'double precision' do
      let(:data_type) { 'double precision' }
      it { expect(subject).to eq 'FLOAT64' }
    end

    context 'character' do
      let(:data_type) { 'character' }
      it { expect(subject).to eq 'STRING' }
    end

    context 'character varying' do
      let(:data_type) { 'character varying' }
      it { expect(subject).to eq 'STRING' }
    end

    context 'text' do
      let(:data_type) { 'text' }
      it { expect(subject).to eq 'STRING' }
    end

    context 'date' do
      let(:data_type) { 'date' }
      it { expect(subject).to eq 'TIMESTAMP' }
    end

    context 'timestamp' do
      let(:data_type) { 'timestamp' }
      it { expect(subject).to eq 'TIMESTAMP' }
    end

    context 'timestamp with time zone' do
      let(:data_type) { 'timestamp with time zone' }
      it { expect(subject).to eq 'TIMESTAMP' }
    end

    context 'boolean' do
      let(:data_type) { 'boolean' }
      it { expect(subject).to eq 'BOOL' }
    end
  end

  describe '#converted_value' do
    subject { column.converted_value }

    context 'datetime' do
      let(:column_name) { 'create_at' }
      let(:data_type) { 'timestamp with time zone' }
      it { expect(subject).to eq 'EXTRACT(EPOCH FROM "create_at") AS "create_at"' }
    end

    context 'int' do
      let(:column_name) { 'id' }
      let(:data_type) { 'int' }
      it { expect(subject).to eq '"id"' }
    end

    context 'varchar' do
      let(:column_name) { 'explanation' }
      let(:data_type) { 'varchar' }
      it { expect(subject).to eq '"explanation"' }
    end
  end

  describe '#to_json' do
    subject { column.to_json }

    let(:column_name) { 'id' }
    let(:data_type) { 'integer' }
    it { expect(subject).to eq '{"name":"id","type":"INT64"}' }
  end
end
