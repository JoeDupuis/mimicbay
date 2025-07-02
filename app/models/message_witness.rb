class MessageWitness < ApplicationRecord
  belongs_to :message
  belongs_to :character

  validates :character_id, uniqueness: { scope: :message_id }
end
