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
    get "/jobs"
    assert_redirected_to new_session_path
  end
end
