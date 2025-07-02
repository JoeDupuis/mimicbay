class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.references :game, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.json :properties

      t.timestamps
    end
  end
end
