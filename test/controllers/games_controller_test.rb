require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:game_master)
    @game = games(:game_without_characters)
    sign_in_as(@user)
  end

  test "should get index" do
    get games_url
    assert_response :success
  end

  test "should get new" do
    get new_game_url
    assert_response :success
  end

  test "should create game" do
    assert_difference("Game.count") do
      post games_url, params: { game: { name: "New Game" } }
    end

    assert_redirected_to game_url(Game.last)
  end

  test "should show game when in creating state" do
    @game.update!(state: :creating)
    get game_url(@game)
    assert_response :success
  end

  test "should redirect show to play controller when playing with player character" do
    @game.characters.create!(name: "Player", is_player: true)
    @game.update!(state: :playing)
    get game_url(@game)
    assert_redirected_to game_play_url(@game)
  end

  test "should not allow updating to playing state without player character" do
    patch game_url(@game), params: { game: { state: "playing" } }
    assert_response :unprocessable_entity
    @game.reload
    assert @game.creating?
  end

  test "should get edit" do
    get edit_game_url(@game)
    assert_response :success
  end

  test "should update game" do
    patch game_url(@game), params: { game: { name: "Updated Name" } }
    assert_redirected_to game_url(@game)
  end

  test "should destroy game" do
    assert_difference("Game.count", -1) do
      delete game_url(@game)
    end

    assert_redirected_to games_url
  end

  test "should require authentication" do
    sign_out
    get games_url
    assert_redirected_to new_session_url
  end

  test "should not show other user's game" do
    other_game = games(:other_users_game)
    get game_url(other_game)
    assert_response :not_found
  end
end
