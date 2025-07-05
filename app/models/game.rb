class Game < ApplicationRecord
  belongs_to :user
  has_many :areas, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one :game_configuration_session, dependent: :destroy do
    def find_or_create_with_system_message!
      find_or_create_by!(game: proxy_association.owner) do |session|
        session.game_configuration_messages.create!(
          role: :system,
          content: GameConfigurationSession::SYSTEM_PROMPT
        )
      end
    end
  end

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
