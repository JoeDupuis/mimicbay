require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password")
    @game = @user.games.create!(name: "Test Game")
    @area = @game.areas.create!(name: "Test Area")
    @character = @game.characters.create!(name: "Test Character", area: @area)
  end

  test "should be valid with all required attributes" do
    message = @game.messages.build(
      content: "Hello",
      message_type: "chat",
      character: @character,
      area: @area
    )
    assert message.valid?
  end

  test "should be valid without character for system messages" do
    message = @game.messages.build(
      content: "Player entered the room",
      message_type: "system",
      area: @area
    )
    assert message.valid?
  end

  test "should require content" do
    message = @game.messages.build(
      message_type: "chat",
      character: @character,
      area: @area
    )
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "should require valid message_type" do
    message = @game.messages.build(
      content: "Hello",
      message_type: "invalid",
      character: @character,
      area: @area
    )
    assert_not message.valid?
    assert_includes message.errors[:message_type], "is not included in the list"
  end

  test "should have witnesses through message_witnesses" do
    witness1 = @game.characters.create!(name: "Witness 1", area: @area)
    witness2 = @game.characters.create!(name: "Witness 2", area: @area)

    message = @game.messages.create!(
      content: "Hello",
      message_type: "chat",
      character: @character,
      area: @area
    )

    # Witnesses are created automatically via callback
    assert_equal 3, message.witnesses.count
    assert_includes message.witnesses, @character
    assert_includes message.witnesses, witness1
    assert_includes message.witnesses, witness2
  end
end
