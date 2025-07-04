require "test_helper"

class Games::PlayControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:game_master)
    @game = games(:game_without_characters)
    sign_in_as(@user)
  end

  test "should get show" do
    @game.characters.create!(name: "Player", is_player: true)
    @game.update!(state: "playing")
    get game_play_url(@game)
    assert_response :success
  end

  test "should redirect if no player character" do
    game_without_player = games(:game_without_characters)  # Game without characters
    get game_play_url(game_without_player)
    assert_redirected_to game_without_player
  end

  test "should require authentication" do
    sign_out
    get game_play_url(@game)
    assert_redirected_to new_session_url
  end

  test "should not show other user's game" do
    other_game = games(:other_users_game)
    get game_play_url(other_game)
    assert_response :not_found
  end
end
