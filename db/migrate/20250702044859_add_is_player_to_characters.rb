class AddIsPlayerToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :is_player, :boolean, default: false, null: false
    add_index :characters, [ :game_id, :is_player ], where: "is_player = true", unique: true
  end
end
