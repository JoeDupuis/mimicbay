class GameConfigurationSession < ApplicationRecord
  SYSTEM_PROMPT = "You are a helpful game configuration assistant. Help the user create areas and characters for their tabletop RPG game. Use the provided tools to create, update, list, and delete game entities based on the user's descriptions.".freeze

  belongs_to :game
  has_many :game_configuration_messages, dependent: :destroy

  before_validation :create_system_message, on: :create

  def messages
    game_configuration_messages.order(:created_at)
  end

  def prompt(content, model: nil)
    game_configuration_messages.create!(role: :user, content: content)
    ProcessLlmResponseJob.perform_later(id, model) if model.present?
  end

  private

  def create_system_message
    game_configuration_messages.build(
      role: :system,
      content: SYSTEM_PROMPT
    )
  end
end
