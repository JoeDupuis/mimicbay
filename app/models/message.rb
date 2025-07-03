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
  after_create_commit :broadcast_to_channels

  private

  def create_witnesses
    if character.nil?
      # DM message
      create_dm_witnesses(target_character_id)
    else
      # Player message
      create_player_witnesses
    end
  end

  def broadcast_to_channels
    # Broadcast to all witnesses
    witnesses.each do |character|
      Turbo::StreamsChannel.broadcast_append_to(
        "game_#{game.id}_character_#{character.id}_messages",
        target: "messages",
        partial: "games/messages/message",
        locals: { message: self, player_character: character }
      )
    end

    # Also broadcast to DM channel so DM sees all messages
    Turbo::StreamsChannel.broadcast_append_to(
      "game_#{game.id}_dm_messages",
      target: "messages",
      partial: "games/messages/message",
      locals: { message: self, player_character: nil, is_dm_view: true }
    )
  end

  def create_dm_witnesses(target_character_id)
    if area_id.present?
      # Area-based message
      characters_in_area = game.characters.where(area_id: area_id)
      characters_in_area.each do |character|
        message_witnesses.create(character: character)
      end
    elsif target_character_id.present?
      # Private message to specific character
      target_character = game.characters.find_by(id: target_character_id)
      if target_character
        message_witnesses.create(character: target_character)
      end
    else
      # Broadcast to all
      game.characters.each do |character|
        message_witnesses.create(character: character)
      end
    end
  end

  def create_player_witnesses
    if area.present?
      # Area-based message: all characters in area can see it
      characters_in_area = game.characters.where(area: area)
      characters_in_area.each do |character|
        message_witnesses.create(character: character)
      end
    else
      # Private message: only sender can see it
      message_witnesses.create(character: character) if character
    end
  end
end
