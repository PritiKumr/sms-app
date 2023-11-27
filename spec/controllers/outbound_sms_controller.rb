require 'rails_helper'

RSpec.describe OutboundSmsController, type: :controller do
  let(:valid_params) do
    {
      from: '1234567890',
      to: '9876543210',
      text: 'Hello, world!'
    }
  end

  describe 'POST #create' do
    context 'with valid input' do
      it 'returns success response' do
        allow(controller).to receive(:authorized?).and_return(true)
        allow(controller).to receive(:validate_phone_number)
        allow(controller).to receive(:validate_stop_cache)
        allow(controller).to receive(:validate_request_limit)

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(200)
        expect(json['message']).to eq('outbound sms ok')
        expect(json['error']).to eq('')
      end
    end

    context 'when JSON format is invalid' do
      it 'returns a 400 Bad Request response' do
        allow(controller).to receive(:authorized?).and_return(true)

        post :create, body: 'invalid_json'

        expect(response).to have_http_status(400)
        expect(json['message']).to eq('')
        expect(json['error']).to eq('Invalid JSON format')
      end
    end

    context 'when parameter is missing' do
      it 'returns a 422 Unprocessable Entity response' do
        allow(controller).to receive(:authorized?).and_return(true)

        post :create, body: { from: '1234567890', text: 'Hello, world!' }.to_json

        expect(response).to have_http_status(422)
        expect(json['message']).to eq('')
        expect(json['error']).to eq('to is missing')
      end
    end

    context 'when phone number validation fails' do
      it 'raises StandardError and returns a 422 response' do
        allow(controller).to receive(:authorized?).and_return(true)
        allow(controller).to receive(:validate_phone_number).and_raise(StandardError, 'Invalid phone number')

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(422)
        expect(json['message']).to eq('')
        expect(json['error']).to eq('Invalid phone number')
      end
    end

    context 'when STOP cache validation fails' do
      it 'raises StandardError and returns a 422 response' do
        allow(controller).to receive(:authorized?).and_return(true)
        allow(controller).to receive(:validate_stop_cache).and_raise(StandardError)

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(422)
      end
    end

    context 'when request limit validation fails' do
      it 'raises StandardError and returns a 422 response' do
        allow(controller).to receive(:authorized?).and_return(true)
        allow(controller).to receive(:validate_phone_number).and_return(true)
        allow(controller).to receive(:validate_request_limit).and_raise(StandardError)

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(422)
      end
    end

    context 'when unknown failure occurs' do
      it 'raises StandardError and returns a 422 response' do
        allow(controller).to receive(:authorized?).and_return(true)
        allow(controller).to receive(:validate_phone_number).and_raise(StandardError, 'Unknown failure')

        post :create, body: valid_params.to_json

        expect(response).to have_http_status(422)
        expect(json['message']).to eq('')
        expect(json['error']).to eq('Unknown failure')
      end
    end
  end

  private

  def json
    JSON.parse(response.body)
  end
end
