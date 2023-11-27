Rails.application.routes.draw do
  post '/inbound/sms', to: 'inbound_sms#create'
  post '/outbound/sms', to: 'outbound_sms#create'

  # Catch-all route for any other HTTP methods
  match '*path', to: 'application#method_not_allowed', via: :all
end