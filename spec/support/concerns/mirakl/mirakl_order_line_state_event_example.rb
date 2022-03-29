# frozen_string_literal: true

RSpec.shared_examples 'a mirakl order line state event' do |start_state, end_state|
  let(:mirakl_order_line) { create :mirakl_order_line, state: start_state }
  let(:order_line_payload) do
    { 'order_line_id' => mirakl_order_line.mirakl_order_line_id,
      'order_line_state' => end_state }
  end

  before do
    allow(mirakl_order_line).to receive_messages("#{end_state.downcase}!": true)
    allow(Mirakl::ProcessReimbursementsOrganizer).to receive(:call)

    mirakl_order_line.process_update!(order_line_payload)
  end

  it "triggers the event #{end_state.downcase}!" do
    expect(mirakl_order_line).to have_received("#{end_state.downcase}!".to_sym)
  end

  it 'calls Mirakl::ProcessReimbursementsOrganizer' do
    expect(Mirakl::ProcessReimbursementsOrganizer).to have_received(:call).with(mirakl_order: mirakl_order_line.order,
                                                                                mirakl_order_line: mirakl_order_line,
                                                                                order_line_payload: order_line_payload)
  end

  context 'when it is already in the state returned by mirakl' do
    let(:mirakl_order_line) { create :mirakl_order_line, state: end_state }

    it 'does not trigger the event' do
      expect(mirakl_order_line).not_to have_received("#{end_state.downcase}!".to_sym)
    end
  end
end
