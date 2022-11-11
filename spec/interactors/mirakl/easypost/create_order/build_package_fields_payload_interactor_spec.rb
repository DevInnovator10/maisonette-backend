# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::CreateOrder::BuildPackageFieldsPayloadInteractor, mirakl: true do
    describe '#call' do
    let(:interactor) { described_class.new(boxes: boxes, update_mirakl: update_mirakl, mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }
    let(:payload) { interactor.context.mirakl_order_additional_fields_payload }
    let(:boxes) { [box1, box2, box3] }
    let(:box1) { { length: 5.6, width: 7, height: 5, weight: 10.55123456789745616 } }
    let(:box2) { { length: 6.5, width: 3.5, height: 12, weight: 1.55 } }
    let(:box3) { { name: 'mailer-10-8-3', length: 10.0, height: 8.0, weight: 0.7, width: 3 } }

    context 'when it is successful' do
      before do
        interactor.call
      end

      context 'when update_mirakl is false' do
        let(:update_mirakl) { false }

        it 'does not update the payload' do
          expect(payload).to eq nil
        end

      end

      context 'when update_mirakl is true' do
        let(:update_mirakl) { true }
        let(:order_package_fields_payload) do
          [{ code: 'box1-packaged-weight', value: 10.55 },
           { code: 'box1-packaged-length', value: 5.6 },
           { code: 'box1-packaged-height', value: 5 },
           { code: 'box1-packaged-width-depth', value: 7 },

           { code: 'box2-packaged-weight', value: 1.55 },
           { code: 'box2-packaged-length', value: 6.5 },
           { code: 'box2-packaged-height', value: 12 },
           { code: 'box2-packaged-width-depth', value: 3.5 },

           { code: 'box3-packaged-weight', value: 0.7 },
           { code: 'box3-packaged-length', value: 10.0 },
           { code: 'box3-packaged-height', value: 8.0 },
           { code: 'box3-packaged-width-depth', value: 3 },
           { code: 'box3-package-name', value: 'mailer-10-8-3' }]
        end

        it 'updates the payload' do
          expect(payload).to eq order_package_fields_payload
        end
      end
    end

    context 'when it errors' do
      let(:update_mirakl) { true }
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:boxes).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end
end
