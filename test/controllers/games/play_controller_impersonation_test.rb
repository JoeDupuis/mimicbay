require "test_helper"

class Games::PlayControllerImpersonationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @game = games(:three)
    @player_character = characters(:one)
    @npc_character = characters(:two)
    @game.update!(state: "playing")
    sign_in_as @user
  end

  test "game owner can impersonate any character" do
    get game_play_path(@game, character_id: @npc_character.id)
    assert_response :success
    assert_select ".player-info", text: /Playing as: #{@npc_character.name}/
    assert_select ".badge-warning", text: "(DM Impersonating)"
  end

  test "non-owner cannot impersonate characters" do
    # Trying to access a game you don't own results in 404
    # because the set_game before_action only finds games owned by current user
    other_game = @other_user.games.create!(name: "Other Game", state: "creating")
    other_player = other_game.characters.create!(name: "Other Player", is_player: true)
    other_npc = other_game.characters.create!(name: "Other NPC", is_player: false)
    other_game.update!(state: "playing")
    
    # Sign in as first user and try to access other user's game
    get game_play_path(other_game, character_id: other_npc.id)
    assert_response :not_found
  end

  test "regular play without impersonation shows player character" do
    get game_play_path(@game)
    assert_response :success
    assert_select ".player-info", text: /Playing as: #{@player_character.name}/
    assert_select ".badge-warning", false
  end

  test "messages sent while impersonating come from impersonated character" do
    assert_difference "Message.count" do
      post game_messages_path(@game), params: {
        message: { content: "Hello from NPC" },
        character_id: @npc_character.id
      }
    end
    
    message = Message.last
    assert_equal @npc_character, message.character
    assert_equal "Hello from NPC", message.content
  end

  test "DM view shows links to impersonate all characters" do
    get game_dm_path(@game)
    assert_response :success
    
    @game.characters.each do |character|
      assert_select "a[href='#{game_play_path(@game, character_id: character.id)}']", text: /Open as #{character.name}/
    end
  end
end