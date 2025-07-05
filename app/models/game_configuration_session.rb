class GameConfigurationSession < ApplicationRecord
  belongs_to :game
  has_many :game_configuration_messages, dependent: :destroy

  def messages
    game_configuration_messages.order(:created_at)
  end
end
