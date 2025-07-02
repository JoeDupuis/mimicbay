class Game < ApplicationRecord
  belongs_to :user
  has_many :areas, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true

  enum :state, { creating: 0, playing: 1 }, default: :creating
end
