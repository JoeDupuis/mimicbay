require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @game = games(:one)
    sign_in_as @user
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get game_characters_url(@game)
    assert_redirected_to new_session_url
  end

  test "should not allow access to other user's game characters" do
    other_game = games(:two)
    get game_characters_url(other_game)
    assert_response :not_found
  end

  test "should get index" do
    get game_characters_url(@game)
    assert_response :success
  end

  test "should get new" do
    get new_game_character_url(@game)
    assert_response :success
  end

  test "should create character" do
    assert_difference("Character.count") do
      post game_characters_url(@game), params: {
        character: {
          name: "Test Character",
          description: "A test character",
          properties: { test: "value" }.to_json
        }
      }
    end

    assert_redirected_to game_characters_url(@game)
  end

  test "should not create character with invalid params" do
    assert_no_difference("Character.count") do
      post game_characters_url(@game), params: {
        character: {
          name: "",
          description: "A test character"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show character" do
    character = Character.create!(game: @game, name: "Test Character", description: "Test")
    get game_character_url(@game, character)
    assert_response :success
  end

  test "should get edit" do
    character = Character.create!(game: @game, name: "Test Character", description: "Test")
    get edit_game_character_url(@game, character)
    assert_response :success
  end

  test "should update character" do
    character = Character.create!(game: @game, name: "Test Character", description: "Test")
    patch game_character_url(@game, character), params: {
      character: {
        name: "Updated Character",
        description: "Updated description"
      }
    }
    assert_redirected_to game_character_url(@game, character)
    character.reload
    assert_equal "Updated Character", character.name
  end

  test "should destroy character" do
    character = Character.create!(game: @game, name: "Test Character", description: "Test")
    assert_difference("Character.count", -1) do
      delete game_character_url(@game, character)
    end

    assert_redirected_to game_characters_url(@game)
  end

  test "should not access characters from wrong game" do
    other_game = Game.create!(user: @user, name: "Other Game")
    character = Character.create!(game: other_game, name: "Test Character", description: "Test")

    get game_character_url(@game, character)
    assert_response :not_found
  end
end
