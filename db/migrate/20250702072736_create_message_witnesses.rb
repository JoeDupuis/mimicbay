class CreateMessageWitnesses < ActiveRecord::Migration[8.1]
  def change
    create_table :message_witnesses do |t|
      t.references :message, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end

    add_index :message_witnesses, [ :message_id, :character_id ], unique: true
  end
end
