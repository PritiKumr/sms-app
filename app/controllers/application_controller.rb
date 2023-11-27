class ApplicationController < ActionController::API
  def method_not_allowed
    render plain: 'Method Not Allowed', status: 405
  end
end
