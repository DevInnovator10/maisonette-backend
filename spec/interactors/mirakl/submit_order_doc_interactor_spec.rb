# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SubmitOrderDocInteractor, mirakl: true do
  let(:interactor) { described_class.new mirakl_order: mirakl_order, binary_file: binary_file, doc_type: doc_type }
  let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: logistic_order_id }
  let(:logistic_order_id) { 'R1234-A' }
  let(:path) { 'some_path.pdf' }
  let(:doc_type) { 'document_type' }
  let(:payload) { { files: binary_file, order_documents: order_documents } }
  let(:order_documents) do
    <<~XML
      <body>
        <order_documents>
          <order_document>
            <file_name>#{binary_file.path}</file_name>
            <type_code>#{doc_type.upcase}</type_code>
          </order_document>
        </order_documents>
       </body>
    XML
  end

  context 'when it is successful' do
    before do
      allow(interactor).to receive(:post)

      interactor.call
    end

    context 'when there is a binary_file' do
      let(:binary_file) { instance_double Mirakl::BinaryFileStringIO, path: path }

      it 'calls /orders/{logistic_order_id}/documents with the binary_file' do
        expect(interactor).to have_received(:post).with("/orders/#{logistic_order_id}/documents",
                                                        payload: payload)
      end

      context 'when there is only logistic_order and no mirakl_order' do
        let(:interactor) do
          described_class.new logistic_order_id: logistic_order_id, binary_file: binary_file, doc_type: doc_type
        end
        let(:mirakl_order) {}
        let(:logistic_order_id) { 'R1234-A' }

        it 'calls /orders/{logistic_order_id}/documents with the binary_file' do
          expect(interactor).to have_received(:post).with("/orders/#{logistic_order_id}/documents",
                                                          payload: payload)
        end
      end
    end

    context 'when there is no binary_file' do
      let(:binary_file) { nil }

      it 'does not call /orders/{logistic_order_id}/documents' do
        expect(interactor).not_to have_received(:post)
      end
    end
  end

  context 'when an error is thrown' do
    let(:binary_file) { 'foo' }
    let(:exception) { StandardError.new 'some error' }

    before do
      allow(interactor).to receive_messages(rescue_and_capture: false)
      allow(interactor).to receive(:payload).and_raise(exception)
    end

    it 'does fail the interactor' do
      expect { interactor.call }.to raise_exception(Interactor::Failure)

      expect(interactor.context).to be_failure
    end

    it 'calls rescue_and_capture' do
      expect { interactor.call }.to raise_exception(Interactor::Failure)

      expect(interactor).to(
        have_received(:rescue_and_capture).with(exception,
                                                extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
      )
    end
  end
end
