module ValidationConcern
  extend ActiveSupport::Concern

  REDIS = Redis.new(url: 'redis://localhost:6379')

  private

  def validate_http_method
    method_not_allowed unless request.post?
  end

  def authenticate
    authorization_header = request.headers['Authorization']
    unless authorized?(authorization_header)
      render json: { message: '', error: 'Unauthorized' }, status: 403
    end
  end

  def authorized?(authorization_header)
    return false if authorization_header.nil?
    return false unless authorization_header

    auth_type, encoded_credentials = authorization_header.split(' ')
    return false unless auth_type == 'Basic'

    credentials = Base64.decode64(encoded_credentials).split(':')
    username = credentials[0]
    password = credentials[1]


    @account = Account.find_by(username: username, auth_id: password)
    !@account.nil?
  end

  def render_error_response(error_message, status)
    render json: { message: '', error: error_message }, status: status
  end
  
  def validate_input(payload)
    required_params = %w[from to text]
    input_valid_params = %w[from to]

    required_params.each do |param|
      raise ActionController::ParameterMissing.new(param) unless payload.key?(param)
    end

    input_valid_params.each do |param|
      raise StandardError.new("#{param} is invalid") unless validate_length(payload[param])
    end
  end

  def validate_length(number)
    number.to_i > 0 && number.length >= 6 && number.length <= 16
  end

  def validate_phone_number(param, number)
    unless phone_number_exists?(number)
      raise StandardError.new("#{param} parameter not found")
    end
  end

  def phone_number_exists?(number)
    PhoneNumber.find_by(account_id: @account.id, number: number).present?
  end


  def process_stop_message(from, to, text)
    stop_messages = %w[STOP STOP\n STOP\r STOP\r\n]
  
    if stop_messages.include?(text)
      cache_key = "#{from}_#{to}"
      REDIS.setex(cache_key, 4 * 60 * 60, 'stop')
    end
  end
end