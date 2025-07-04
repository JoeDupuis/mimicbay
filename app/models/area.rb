class Area < ApplicationRecord
  belongs_to :game
  has_many :characters, dependent: :nullify
  has_many :messages, dependent: :destroy

  validates :name, presence: true
end
