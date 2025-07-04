require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should have creating state by default" do
    game = Game.new(name: "Test Game", user: users(:one))
    assert_equal "creating", game.state
  end

  test "should be able to set playing state" do
    game = Game.new(name: "Test Game", user: users(:one))
    game.save!
    game.characters.create!(name: "Test Player", is_player: true)
    game.state = :playing
    game.save!
    assert_equal "playing", game.state
  end

  test "should respond to state query methods" do
    game = games(:one)
    assert game.creating?
    assert_not game.playing?

    # Create a player character before changing to playing state
    game.characters.create!(name: "Test Player", is_player: true)

    game.playing!
    assert game.playing?
    assert_not game.creating?
  end

  test "should not allow playing state without player character" do
    game = games(:one)
    game.state = :playing
    assert_not game.valid?
    assert_includes game.errors[:base], "You must create a player character before starting the game"
  end

  test "should allow playing state with player character" do
    game = games(:one)
    game.characters.create!(name: "Test Player", is_player: true)
    game.state = :playing
    assert game.valid?
  end
end
