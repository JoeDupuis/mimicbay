require "test_helper"

class Games::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password")
    @game = @user.games.create!(name: "Test Game", state: "playing")
    @area = @game.areas.create!(name: "Starting Room")
    @player_character = @game.characters.create!(name: "Player", is_player: true, area: @area)
    @npc = @game.characters.create!(name: "NPC", is_player: false, area: @area)

    sign_in_as(@user)
  end

  test "should create message with witnesses" do
    assert_difference("Message.count") do
      assert_difference("MessageWitness.count", 2) do
        post game_messages_url(@game), params: { message: { content: "Hello world!" } }
      end
    end

    message = Message.last
    assert_equal "Hello world!", message.content
    assert_equal @player_character, message.character
    assert_equal @area, message.area
    assert_equal "chat", message.message_type

    witnesses = message.witnesses
    assert_includes witnesses, @player_character
    assert_includes witnesses, @npc
  end

  test "should not create message without content" do
    assert_no_difference("Message.count") do
      post game_messages_url(@game), params: { message: { content: "" } }
    end
  end

  test "should redirect if no player character" do
    @player_character.destroy

    post game_messages_url(@game), params: { message: { content: "Hello" } }
    assert_redirected_to game_play_path(@game)
  end

  test "should only create witnesses for characters in same area" do
    other_area = @game.areas.create!(name: "Other Room")
    other_character = @game.characters.create!(name: "Other", is_player: false, area: other_area)

    assert_difference("MessageWitness.count", 2) do
      post game_messages_url(@game), params: { message: { content: "Hello!" } }
    end

    message = Message.last
    witnesses = message.witnesses
    assert_includes witnesses, @player_character
    assert_includes witnesses, @npc
    assert_not_includes witnesses, other_character
  end
end
