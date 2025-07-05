class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :games, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { standard: 0, admin: 1 }
end
