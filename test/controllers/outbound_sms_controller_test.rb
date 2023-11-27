require "test_helper"

class OutboundSmsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get outbound_sms_create_url
    assert_response :success
  end
end
