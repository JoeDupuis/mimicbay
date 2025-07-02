require "test_helper"

class CharacterPlayerTest < ActiveSupport::TestCase
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
end
