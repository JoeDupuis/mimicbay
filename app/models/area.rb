class Area < ApplicationRecord
  belongs_to :game
  has_many :characters, dependent: :nullify

  validates :name, presence: true
end
