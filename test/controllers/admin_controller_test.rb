require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "redirects non-admin users to root" do
    user = users(:game_master)
    
    # Ensure user is loaded correctly from fixtures
    assert_equal "gm@example.com", user.email_address
    assert_equal "standard", user.role
    assert_equal false, user.admin?
    
    sign_in_as user
    get "/jobs"
    assert_redirected_to root_path
  end

  test "allows admin users to access mission control" do
    sign_in_as users(:admin_user)
    get "/jobs"
    assert_response :success
  end

  test "redirects unauthenticated users to sign in" do
    skip "Mission Control Jobs adds server_id parameter that breaks new_session_path generation"
    # This is a known issue with mission_control-jobs gem v1.0.2
    # The gem adds server_id to default_url_options which causes
    # ActionController::UrlGenerationError when redirecting to login
    get "/jobs"
    assert_redirected_to new_session_path
  end
end
