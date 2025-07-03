class Message < ApplicationRecord
  belongs_to :game
  belongs_to :character, optional: true
  belongs_to :area, optional: true

  has_many :message_witnesses, dependent: :destroy
  has_many :witnesses, through: :message_witnesses, source: :character

  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[chat action system] }
end
