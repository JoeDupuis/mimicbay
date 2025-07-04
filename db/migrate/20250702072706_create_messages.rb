class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.text :content
      t.string :message_type
      t.references :game, null: false, foreign_key: true
      t.references :character, null: true, foreign_key: true
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
