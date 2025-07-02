require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @game = games(:one)
  end

  test "should allow setting a character as player" do
    character = @game.characters.create!(name: "Hero", is_player: true)
    assert character.is_player?
  end

  test "should only allow one player character per game" do
    character1 = @game.characters.create!(name: "Hero 1", is_player: true)
    character2 = @game.characters.create!(name: "Hero 2", is_player: false)

    character2.update!(is_player: true)

    character1.reload
    character2.reload

    assert_not character1.is_player?
    assert character2.is_player?
  end

  test "should allow multiple non-player characters" do
    npc1 = @game.characters.create!(name: "NPC 1", is_player: false)
    npc2 = @game.characters.create!(name: "NPC 2", is_player: false)

    assert_not npc1.is_player?
    assert_not npc2.is_player?
  end

  test "should scope player and non_player correctly" do
    @game.characters.destroy_all

    player = @game.characters.create!(name: "Player", is_player: true)
    npc1 = @game.characters.create!(name: "NPC 1", is_player: false)
    npc2 = @game.characters.create!(name: "NPC 2", is_player: false)

    assert_equal 1, @game.characters.player.count
    assert_equal 2, @game.characters.non_player.count
    assert_includes @game.characters.player, player
    assert_includes @game.characters.non_player, npc1
    assert_includes @game.characters.non_player, npc2
  end

  test "should track witnessed messages in order" do
    area = @game.areas.create!(name: "Room 1")
    character = @game.characters.create!(name: "Test Character", area: area)
    other_character = @game.characters.create!(name: "Other", area: area)

    message1 = @game.messages.create!(
      content: "First message",
      message_type: "chat",
      character: other_character,
      area: area,
      created_at: 2.minutes.ago
    )
    message1.message_witnesses.create!(character: character)

    message2 = @game.messages.create!(
      content: "Second message",
      message_type: "chat",
      character: character,
      area: area,
      created_at: 1.minute.ago
    )
    message2.message_witnesses.create!(character: character)

    witnessed = character.witnessed_messages_in_order
    assert_equal 2, witnessed.count
    assert_equal "First message", witnessed.first.content
    assert_equal "Second message", witnessed.last.content
  end

  test "should only see messages from current area" do
    area1 = @game.areas.create!(name: "Room 1")
    area2 = @game.areas.create!(name: "Room 2")
    character = @game.characters.create!(name: "Test Character", area: area1)
    other_character = @game.characters.create!(name: "Other", area: area2)

    message_in_area1 = @game.messages.create!(
      content: "Message in area 1",
      message_type: "chat",
      character: character,
      area: area1
    )
    message_in_area1.message_witnesses.create!(character: character)

    message_in_area2 = @game.messages.create!(
      content: "Message in area 2",
      message_type: "chat",
      character: other_character,
      area: area2
    )

    witnessed = character.witnessed_messages
    assert_includes witnessed, message_in_area1
    assert_not_includes witnessed, message_in_area2
  end

  test "should track area changes in message history" do
    area1 = @game.areas.create!(name: "Room 1")
    area2 = @game.areas.create!(name: "Room 2")
    character = @game.characters.create!(name: "Test Character", area: area1)

    message1 = @game.messages.create!(
      content: "In room 1",
      message_type: "chat",
      character: character,
      area: area1
    )
    message1.message_witnesses.create!(character: character)

    character.update!(area: area2)

    message2 = @game.messages.create!(
      content: "In room 2",
      message_type: "chat",
      character: character,
      area: area2
    )
    message2.message_witnesses.create!(character: character)

    witnessed = character.witnessed_messages_in_order
    assert_equal 2, witnessed.count
    assert_equal area1, witnessed.first.area
    assert_equal area2, witnessed.last.area
  end
end
