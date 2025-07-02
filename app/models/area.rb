class Area < ApplicationRecord
  belongs_to :game

  validates :name, presence: true
end
