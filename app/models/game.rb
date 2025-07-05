class Game < ApplicationRecord
  belongs_to :user
  has_many :areas, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one :game_configuration_session, dependent: :destroy

  validates :name, presence: true
  validate :requires_player_character_to_play
  validate :llm_adapter_must_be_valid

  enum :state, { creating: 0, playing: 1 }, default: :creating

  def llm_adapter_instance(model: nil)
    return nil unless llm_adapter.present?

    adapter_class = "LLM::#{llm_adapter}".constantize
    adapter_class.new(model: model, user_id: user_id)
  end

  private

  def requires_player_character_to_play
    if playing? && characters.player.empty?
      errors.add(:base, "You must create a player character before starting the game")
    end
  end

  def llm_adapter_must_be_valid
    return unless llm_adapter.present?

    begin
      adapter_class = "LLM::#{llm_adapter}".constantize
      unless adapter_class < LLM::Base
        errors.add(:llm_adapter, "must be a subclass of LLM::Base")
      end
    rescue NameError
      errors.add(:llm_adapter, "is not a valid class")
    end
  end
end
