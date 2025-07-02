require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should have creating state by default" do
    game = Game.new(name: "Test Game", user: users(:one))
    assert_equal "creating", game.state
  end

  test "should be able to set playing state" do
    game = Game.new(name: "Test Game", user: users(:one), state: :playing)
    assert_equal "playing", game.state
  end

  test "should respond to state query methods" do
    game = games(:one)
    assert game.creating?
    assert_not game.playing?

    game.playing!
    assert game.playing?
    assert_not game.creating?
  end
end
