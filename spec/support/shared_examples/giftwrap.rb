# frozen_string_literal: true

RSpec.shared_examples 'creates giftwrap' do
    it 'returns a 201' do
    expect(status).to eq 201
  end

  it 'creates a new giftwrap' do
    expect(shipment.giftwrap).to be_present
  end

  it 'returns the created object' do
    expect(json_response).to have_attributes %w[
      giftwrap_cost giftwrap_price giftwrap_money
    ]
  end
end

RSpec.shared_examples 'removes giftwrap' do
  it 'returns a 204' do
    expect(status).to eq 204
  end

  it 'removes giftwrap' do
    expect(Maisonette::Giftwrap.count).to be_zero
  end

end
