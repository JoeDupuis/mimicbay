class MessageWitness < ApplicationRecord
  belongs_to :message
  belongs_to :character

  validates :character_id, uniqueness: { scope: :message_id }

  after_create_commit :broadcast_to_character

  private

  def broadcast_to_character
    Turbo::StreamsChannel.broadcast_append_to(
      "game_#{message.game.id}_character_#{character.id}_messages",
      target: "messages",
      partial: "games/messages/message",
      locals: { message: message, player_character: character }
    )
  end
end
