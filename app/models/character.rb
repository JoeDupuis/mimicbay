class Character < ApplicationRecord
  belongs_to :game
  belongs_to :area, optional: true

  has_many :sent_messages, class_name: "Message", dependent: :nullify
  has_many :message_witnesses, dependent: :destroy
  has_many :witnessed_messages, through: :message_witnesses, source: :message

  validates :name, presence: true

  before_save :ensure_only_one_player

  scope :player, -> { where(is_player: true) }
  scope :non_player, -> { where(is_player: false) }

  def witnessed_messages_in_order
    witnessed_messages.includes(:character, :area).order(created_at: :asc)
  end

  private

  def ensure_only_one_player
    if is_player?
      game.characters.player.where.not(id: id).update_all(is_player: false)
    end
  end
end
