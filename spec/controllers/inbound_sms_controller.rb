require 'rails_helper'

RSpec.describe InboundSmsController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        from: '1234567890',
        to: '9876543210',
        text: ''
      }
    end

    context 'with valid parameters' do
      it 'returns a success response' do
        allow(controller).to receive(:authorized?).and_return(true)

        allow(controller).to receive(:validate_phone_number).and_return(true)

        allow(controller).to receive(:process_stop_message)

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(200)
        expect(response.body).to include('inbound sms ok')
      end
    end

    context 'with missing parameters' do
      it 'returns a 422 Unprocessable Entity status' do
        allow(controller).to receive(:authorized?).and_return(true)

        invalid_params = valid_params.except(:to)

        post :create, body: invalid_params.to_json

        expect(response).to have_http_status(422)
        expect(response.body).to include('to is missing')
      end
    end

    context 'with invalid JSON format' do
      it 'returns a 400 Bad Request status' do
        allow(controller).to receive(:authorized?).and_return(true)

        post :create, body: 'invalid_json'

        expect(response).to have_http_status(400)
        expect(response.body).to include('Invalid JSON format')
      end
    end

    context 'when text contains STOP' do
      it 'calls process_stop_message and returns a success response' do
        allow(controller).to receive(:authorized?).and_return(true)

        stop_params = valid_params.merge(text: 'STOP')
        allow(controller).to receive(:validate_phone_number).and_return(true)

        expect(controller).to receive(:process_stop_message).with(stop_params[:from], stop_params[:to], stop_params[:text])

        post :create, body: stop_params.to_json

        expect(response).to have_http_status(200)
        expect(response.body).to include('inbound sms ok')
      end
    end
  end
end