class GameConfigurationMessage < ApplicationRecord
  belongs_to :game_configuration_session

  enum :role, { user: 0, assistant: 1, tool: 2 }

  validates :content, presence: true, unless: -> { assistant? && tool_calls.present? }

  def tool_call?
    assistant? && tool_calls.present?
  end

  def tool_result?
    tool?
  end
end
