class GameConfigurationMessage < ApplicationRecord
  belongs_to :game_configuration_session

  validates :role, presence: true, inclusion: { in: %w[user assistant tool] }
  validates :content, presence: true, unless: -> { role == "assistant" && tool_calls.present? }

  scope :user, -> { where(role: "user") }
  scope :assistant, -> { where(role: "assistant") }
  scope :tool, -> { where(role: "tool") }

  def tool_call?
    role == "assistant" && tool_calls.present?
  end

  def tool_result?
    role == "tool"
  end
end
