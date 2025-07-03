class Game < ApplicationRecord
  belongs_to :user
  has_many :areas, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validate :requires_player_character_to_play

  enum :state, { creating: 0, playing: 1 }, default: :creating

  private

  def requires_player_character_to_play
    if playing? && characters.player.empty?
      errors.add(:base, "You must create a player character before starting the game")
    end
  end
end
