# frozen_string_literal: true

RSpec.shared_examples 'a Mirakl active record model' do |_|
  it 'defines table_name_prefix' do
    expect(described_class.table_name_prefix).to eq('mirakl_')
  end
end
