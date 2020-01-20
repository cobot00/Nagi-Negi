require 'spec_helper'

RSpec.describe Naginegi::TableConfig do
  describe '.generate_table_configs' do
    subject { Naginegi::TableConfig.generate_table_configs('spec/support/table.yml') }
    let(:db01_hoge) { Naginegi::TableConfig.new({ 'name' => 'hoge', 'daily_snapshot' => true }) }
    let(:db01_simple) { Naginegi::TableConfig.new({ 'name' => 'simple' }) }
    let(:db02_fuga) { Naginegi::TableConfig.new({ 'name' => 'fuga' }) }
    let(:db02_with_condition) { Naginegi::TableConfig.new({ 'name' => 'with_condition', 'condition' => 'created_at < CURRENT_DATE()' }) }

    it { expect(subject['db01'][0]).to eq db01_hoge }
    it { expect(subject['db01'][1]).to eq db01_simple }
    it { expect(subject['db02'][0]).to eq db02_fuga }
    it { expect(subject['db02'][1]).to eq db02_with_condition }
  end
end
