class Message < ApplicationRecord
  belongs_to :game
  belongs_to :character, optional: true
  belongs_to :area, optional: true

  has_many :message_witnesses, dependent: :destroy
  has_many :witnesses, through: :message_witnesses, source: :character

  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[chat action system] }

  attr_accessor :target_character_id

  after_create :create_witnesses
  after_create_commit :broadcast_to_dm_channel

  private

  def create_witnesses
    if is_dm_whisper
      # Player whisper to DM: only the sender can see it
      message_witnesses.create(character: character) if character
    elsif area_id.present?
      # Area-based message: all characters in area can see it
      game.characters.where(area_id: area_id).find_each do |character|
        message_witnesses.create(character: character)
      end
    elsif character.nil?
      # DM message without area
      if target_character_id.present?
        # Private message to specific character
        target_character = game.characters.find_by(id: target_character_id)
        message_witnesses.create(character: target_character) if target_character
      else
        # Broadcast to all characters
        game.characters.find_each do |character|
          message_witnesses.create(character: character)
        end
      end
    else
      # Player message without area: only sender can see it
      message_witnesses.create(character: character)
    end
  end

  def broadcast_to_dm_channel
    # Broadcast to DM channel so DM sees all messages
    Turbo::StreamsChannel.broadcast_append_to(
      "game_#{game.id}_dm_messages",
      target: "messages",
      partial: "games/messages/message",
      locals: { message: self, player_character: nil, is_dm_view: true }
    )
  end
end
