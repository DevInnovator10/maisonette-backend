# frozen_string_literal: true

RSpec.shared_context 'with Narvar context' do
  let(:return_payload) do
    complete_payload_data('spec/fixtures/narvar/returns_rma_payload.yml')
  end

  let(:gift_return_payload) do
    complete_payload_data('spec/fixtures/narvar/gift_returns_rma_payload.yml')
  end

  def complete_payload_data(payload_file_path)
    payload = YAML.load_file(payload_file_path)
    payload['order_number'] = order.number
    payload['items'].each_with_index do |item, i|
      next unless (li = order.line_items[i])

      item['sku'] = li.variant.sku
      item['item_id'] = li.id.to_s
      item['unit_price'] = li.variant.price.to_s
      item['total_item_price'] = li.variant.price.to_s
    end
    payload
  end
end
