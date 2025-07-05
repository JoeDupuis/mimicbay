require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "redirects non-admin users to root" do
    sign_in_as users(:game_master)
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
    # Check we get redirected (the exact path might vary due to engine routing)
    assert_response :redirect
    follow_redirect!
    assert_match(/session\/new/, path)
  end
end
