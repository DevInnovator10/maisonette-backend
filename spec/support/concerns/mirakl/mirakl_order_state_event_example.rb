# frozen_string_literal: true

RSpec.shared_examples 'a mirakl order state event' do |start_state, end_state|
  let(:mirakl_order) do
    build_stubbed :mirakl_order,
                  state: start_state,
                  mirakl_payload_order_state: end_state
  end

  before do
    allow(mirakl_order).to receive_messages("#{end_state.downcase}!": true,
                                            update_incident_flag: true,
                                            process_order_line_update!: nil)

    mirakl_order.process_update!
  end

  it "triggers the event #{end_state.downcase}!" do
    expect(mirakl_order).to have_received("#{end_state.downcase}!".to_sym)
  end

  it 'calls update_incident' do
    expect(mirakl_order).to have_received(:update_incident_flag)
  end

  context 'when it is already in the state returned by mirakl' do
    let(:mirakl_order) do
      build_stubbed :mirakl_order,
                    state: end_state,
                    mirakl_payload_order_state: end_state
    end

    it 'does not trigger the event' do
      expect(mirakl_order).not_to have_received("#{end_state.downcase}!".to_sym)
    end

    it 'calls #update_incident_flag!' do
      expect(mirakl_order).to(have_received(:update_incident_flag))
    end

    it 'calls #process_order_line_update!' do
      expect(mirakl_order).to(
        have_received(:process_order_line_update!).with(mirakl_order.mirakl_payload['order_lines'])
      )
    end
  end
end
