require "test_helper"

class AreasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:game_master)
    @other_user = users(:other_player)
    @game = games(:game_without_characters)
    sign_in_as @user
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get game_areas_url(@game)
    assert_redirected_to new_session_url
  end

  test "should not allow access to other user's game areas" do
    other_game = games(:other_users_game)
    get game_areas_url(other_game)
    assert_response :not_found
  end

  test "should get index" do
    get game_areas_url(@game)
    assert_response :success
  end

  test "should get new" do
    get new_game_area_url(@game)
    assert_response :success
  end

  test "should create area" do
    assert_difference("Area.count") do
      post game_areas_url(@game), params: {
        area: {
          name: "Test Area",
          description: "A test area",
          properties: { test: "value" }.to_json
        }
      }
    end

    assert_redirected_to game_areas_url(@game)
  end

  test "should not create area with invalid params" do
    assert_no_difference("Area.count") do
      post game_areas_url(@game), params: {
        area: {
          name: "",
          description: "A test area"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show area" do
    area = Area.create!(game: @game, name: "Test Area", description: "Test")
    get game_area_url(@game, area)
    assert_response :success
  end

  test "should get edit" do
    area = Area.create!(game: @game, name: "Test Area", description: "Test")
    get edit_game_area_url(@game, area)
    assert_response :success
  end

  test "should update area" do
    area = Area.create!(game: @game, name: "Test Area", description: "Test")
    patch game_area_url(@game, area), params: {
      area: {
        name: "Updated Area",
        description: "Updated description"
      }
    }
    assert_redirected_to game_area_url(@game, area)
    area.reload
    assert_equal "Updated Area", area.name
  end

  test "should destroy area" do
    area = Area.create!(game: @game, name: "Test Area", description: "Test")
    assert_difference("Area.count", -1) do
      delete game_area_url(@game, area)
    end

    assert_redirected_to game_areas_url(@game)
  end

  test "should not access areas from wrong game" do
    other_game = Game.create!(user: @user, name: "Other Game")
    area = Area.create!(game: other_game, name: "Test Area", description: "Test")

    get game_area_url(@game, area)
    assert_response :not_found
  end
end
