class InboundSmsController < ApplicationController

  include ValidationConcern

  before_action :authenticate, :validate_http_method

  def create
    begin
      request_payload = JSON.parse(request.body.read)

      validate_input(request_payload)

      validate_phone_number("to", request_payload['to'])

      process_stop_message(request_payload['from'], request_payload['to'], request_payload['text'])

      render json: { message: 'inbound sms ok', error: '' }
    rescue ActionController::ParameterMissing => e
      render_error_response("#{e.param} is missing", 422)
    rescue JSON::ParserError
      render json: { message: '', error: 'Invalid JSON format' }, status: 400
    rescue StandardError => e
      render json: { message: '', error: e.message || 'unknown failure' }, status: 422
    end
  end

end
