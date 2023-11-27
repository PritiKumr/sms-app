class OutboundSmsController < ApplicationController
  REDIS = Redis.new(url: 'redis://localhost:6379')

  include ValidationConcern

  before_action :authenticate, :validate_http_method

  def create
    begin
      request_payload = JSON.parse(request.body.read)

      validate_input(request_payload)

      validate_phone_number("from", request_payload['from'])

      validate_stop_cache(request_payload['to'], request_payload['from'])

      validate_request_limit(request_payload['from'])

      render json: { message: 'outbound sms ok', error: '' }
    rescue ActionController::ParameterMissing => e
      render_error_response("#{e.param} is missing", 422)
    rescue JSON::ParserError
      render json: { message: '', error: 'Invalid JSON format' }, status: 400
    rescue StandardError => e
      render json: { message: '', error: e.message || 'unknown failure' }, status: 422
    end
  end

  private

  def validate_stop_cache(to, from)
    cache_key = "#{from}_#{to}"
    cached_value = REDIS.get(cache_key)

    if cached_value && cached_value.upcase == 'STOP'
      raise StandardError.new("sms from #{from} to #{to} blocked by STOP request")
    end
  end

  def validate_request_limit(from)
    request_count_key = "#{from}_request_count"
    current_count = REDIS.get(request_count_key).to_i
    limit = 5
    expiry = 24 * 60 * 60

    if current_count >= limit
      raise StandardError.new(" #{from}")
    end

    REDIS.multi do
      REDIS.incr(request_count_key)
      REDIS.expire(request_count_key, expiry) if current_count.zero?
    end
  end
end