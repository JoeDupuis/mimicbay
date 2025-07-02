class Character < ApplicationRecord
  belongs_to :game

  validates :name, presence: true

  before_save :ensure_only_one_player

  scope :player, -> { where(is_player: true) }
  scope :non_player, -> { where(is_player: false) }

  private

  def ensure_only_one_player
    if is_player?
      game.characters.player.where.not(id: id).update_all(is_player: false)
    end
  end
end
