require 'rails_helper'

RSpec.describe ValidationConcern, type: :controller do
  # Dummy controller to include the concern for testing
  controller(ApplicationController) do
    include ValidationConcern

    before_action :authenticate, only: [:index]

    def index
      render json: { message: 'Success' }
    end
  end

  describe '#validate_http_method' do
    it 'does not raise an error for POST requests' do
      request.env['REQUEST_METHOD'] = 'POST'
      expect { get :index }.not_to raise_error
    end
  end

  describe '#authenticate' do
    it 'renders unauthorized if not authorized' do
      get :index
      expect(response).to have_http_status(403)
      expect(json['error']).to eq('Unauthorized')
    end

    it 'renders success if authorized' do
      # Mock an authorized request here
      allow(controller).to receive(:authorized?).and_return(true)
      get :index
      expect(response).to have_http_status(200)
      expect(json['message']).to eq('Success')
    end
  end

  describe '#validate_input' do
    it 'does not raise an error for valid input payload' do
      payload = { 'from' => '123456', 'to' => '654321', 'text' => 'ValidText' }
      expect { controller.send(:validate_input, payload) }.not_to raise_error
    end

    it 'raises ActionController::ParameterMissing for missing parameters' do
      payload = { 'from' => '123456', 'text' => 'ValidText' }
      expect { controller.send(:validate_input, payload) }
        .to raise_error(ActionController::ParameterMissing)
    end

    it 'raises StandardError for invalid parameter length' do
      payload = { 'from' => '123456', 'to' => '654', 'text' => 'ValidText' }
      expect { controller.send(:validate_input, payload) }
        .to raise_error(StandardError, 'to is invalid')
    end
  end

  describe '#validate_phone_number' do
    it 'does not raise an error for an existing phone number' do
      allow(controller).to receive(:phone_number_exists?).and_return(true)
      expect { controller.send(:validate_phone_number, 'param', '1234567890') }.not_to raise_error
    end

    it 'raises StandardError for a non-existing phone number' do
      allow(controller).to receive(:phone_number_exists?).and_return(false)
      expect { controller.send(:validate_phone_number, 'param', '1234567890') }
        .to raise_error(StandardError, 'param parameter not found')
    end
  end

  describe '#process_stop_message' do
    it 'caches the stop message for valid stop messages' do
      allow(ValidationConcern::REDIS).to receive(:setex)
      controller.send(:process_stop_message, '123', '456', 'STOP')
      expect(ValidationConcern::REDIS).to have_received(:setex).with('123_456', kind_of(Numeric), 'stop')
    end

    it 'does not cache for non-stop messages' do
      allow(ValidationConcern::REDIS).to receive(:setex)
      controller.send(:process_stop_message, '123', '456', 'NotAStopMessage')
      expect(ValidationConcern::REDIS).not_to have_received(:setex)
    end
  end

  private

  def json
    JSON.parse(response.body)
  end
end
