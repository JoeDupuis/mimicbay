class AddIsDmToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :is_dm, :boolean, default: false, null: false
    add_index :characters, [ :game_id, :is_dm ], unique: true, where: "is_dm = true"
  end
end
