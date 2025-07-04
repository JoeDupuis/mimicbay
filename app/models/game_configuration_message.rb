class GameConfigurationMessage < ApplicationRecord
  belongs_to :game_configuration_session

  enum :role, { user: 0, assistant: 1, tool: 2, system: 3 }

  validates :content, presence: true, unless: -> { assistant? && tool_calls.present? }

  after_create_commit -> { broadcast_append_to game_configuration_session, partial: "games/configurations/message", locals: { message: self }, target: "configuration-messages" unless system? }

  def tool_call?
    assistant? && tool_calls.present?
  end

  def tool_result?
    tool?
  end
end
